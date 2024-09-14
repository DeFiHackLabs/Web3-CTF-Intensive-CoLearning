# 16 - Preservation

## 題目
[Preservation](https://ethernaut.openzeppelin.com/level/0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed)

### 通關條件
1. 此智慧合約利用一個函式庫來儲存兩個不同時區的兩個不同時間。 建構函數會為每個要儲存的時間創建兩個庫實例。 本關卡的目標是獲得該合約的所有權。
### 提示
1. 查閱 Solidity 文檔中的有關低階函數 delegatecall 的信息，包括其工作原理、如何用於委託操作到鏈上庫以及它對執行範圍的影響。
2. 理解 delegatecall 保持上下文意味著什麼。
3. 理解儲存變數如何儲存和存取。
4. 理解不同資料類型之間轉換的工作原理。
## 筆記
- delegatecall 可以看第 6 題：[06 Delegation](./06_Delegation.md)
- 存變數如何儲存和存取可以看第 8 題：[08 Vault](./08_Vault.md)
- 不同資料類型之間轉換可以看第 13 題：[13 Gatekeeper One](./13_GatekeeperOne.md)
- 可以先想想看：如果發起 delegatecall 和被調用 delegatecall 的兩個合約的初始變數不一樣，會發生什麼事？
- 只要搞懂以上四點，這題就很簡單了。因為 `LibraryContract` 跟 `Preservation` 兩個合約的變數宣告根本不一樣，所以 `LibraryContract` 的 `function setTime(uint256 _time)` 會改變的是 `Preservation` 中 `timeZone1Library` 的值（都是各自合約中第一個變數，也就是說儲存在 slot 1），而 `timeZone1Library` 就是儲存要 delegatecall 的合約地址，所以我們透過第一次呼叫 `setTime()` 將地址改成我們部署的惡意合約，再呼叫一次他就會改成call我們的合約，而我們的合約就是將 owner 換成自己的地址。
