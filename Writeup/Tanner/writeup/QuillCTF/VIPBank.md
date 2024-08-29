
- 目標：讓在 VIPBank deposit 過的 user 無法正常 withdraw

- 方法：可以看到 `withdraw()` 中第一行 `require(address(this).balance <= maxETH, "Cannot withdraw more than 0.5 ETH per transaction");`，此條件限制了 VIPBank 合約的 balance 必須小於 `maxETH (0.5 ether)`，而在未成為 VIP 成員之前，我們是無法透過 deposit 去增加 VIPBank 合約的 balance，因此必須透過部署攻擊合約，並執行 `selfdestruct` 來達到此目的

- 步驟：``forge test --match-contract VIPBankTest -vvv``，前置作業先部署好 VIPBank 合約和設定一位 VIP User，首先利用 `testVIPBankWithdraw()` 檢查 VIP User 可以正常 deposit 和 withdraw，再執行 `testVIPBankExploit` 攻擊，透過 `selfdestruct` 將創建攻擊合約時給予的 0.5 ETH 強制轉入 VIPBank 合約地址，使其 balance 不再小於 `maxETH (0.5 ether)`，即可阻止 VIP User 去操作 withdraw，完成此次目標
