```
// 定義 flashLoan 函數，提供閃電貸款功能
    // amount 為貸款金額，borrower 為借款人地址，target 為調用目標合約，data 為要執行的操作資料
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        // 紀錄貸款前合約的代幣餘額
        uint256 balanceBefore = token.balanceOf(address(this));

        // 將指定數量的代幣轉給借款人
        token.transfer(borrower, amount);
        // 呼叫目標合約並執行傳入的資料操作
        target.functionCall(data);

        // 驗證合約中的代幣餘額是否恢復到貸款前的數量，若不足則觸發還款失敗錯誤
        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        // 若一切正常，返回 true 表示操作成功
        return true;
    }
```
上面的代碼轉成流程就是
![image](https://github.com/user-attachments/assets/c1055bec-83a0-48ea-8893-6be652f27980)
因為檢查是否有還款是依據借出之前的餘額判斷，所以我們可以跟他借0元這樣就不用還款，同時在data部分操作將全額轉出到recovery
