# 15 - Naught Coin

## 題目
[Naught Coin](https://ethernaut.openzeppelin.com/level/0x80934BE6B8B872B364b470Ca30EaAd8AEAC4f63F)

### 通關條件
1. NaughtCoin 是一種 ERC20 代幣，而且你已經持有這些代幣。問題是你只能在等待 10 年的鎖倉期之後才能轉移它們。你能不能嘗試將它們轉移到另一個地址，讓你可以自由地使用它們嗎？要完成這個關卡的話要讓你的帳戶餘額歸零。
### 提示
1. [ERC20 標準](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md)
2. [OpenZeppelin 程式庫](https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts)

## 筆記
- ERC20 就是在智能合約中實現發行 Fungible Token (同質化代幣) 的一種代幣標準。簡單來說只要符合 ERC20 中的規範，就可以在 Ethereum 創造自己的代幣並交易，ERC20 中規範發行代幣的合約必須要實現以下六個功能：
  1. 總供給量：`function totalSupply() public view returns (uint256);`  
  一個代幣的總發行量
  2. 帳戶餘額：`function balanceOf(address _owner) public view returns (uint256 balance)` 
  你剩多少代幣
  3. 轉帳：`function transfer(address _to, uint256 _value) public returns (bool success)`  
  你要轉 `_value` 代幣給 `_to`
  
  前三個比較好理解，後面三個比較像是託管的概念：
  
  4. 授權轉帳：`function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)`  
  從 `_from` 轉 `_value` 個代幣到 `_to`，使用後**授權額度**會減少
  5. 授權：`function approve(address _spender, uint256 _value) public returns (bool success)`  
  允許 `_spender` 可以控制你 `_value` 個代幣，使用後**授權額度**會增加
  6. 授權額度：`function allowance(address _owner, address _spender) public view returns (uint256 remaining)`
  回傳 `_spender` 可以控制 `_owner` 多少代幣

  這幾篇文都有更詳細的介紹：
    - [[EN] What is the ERC20 token standard?](https://www.bitpanda.com/academy/en/lessons/what-is-the-erc20-token-standard/)
    - [[中文] 到底什麼是ERC-20?](https://medium.com/myethacademy/%E5%88%B0%E5%BA%95%E4%BB%80%E9%BA%BC%E6%98%AFerc-20-49d052e8d290)
    - [[中文] WTF Solidity极简入门: 31. ERC20](https://github.com/AmazingAng/WTF-Solidity/tree/main/31_ERC20)
- 理解完 ERC20 後，看回來題目。題目要求我們把自己的代幣歸零，歸零的方法就是把代幣通通轉出去，轉出去可以透過**轉帳(transfer), 授權轉帳(transferFrom)** 兩種方式，但是`transfer()`已經被題目實作而且限制 10 年後才能領取。所以這裡我們只要使用**授權轉帳**  的方法就可以把自己的錢轉出去了。  
**授權轉帳**在上一點介紹ERC20的時候有提到過，要先透過**授權**給別的地址，別的地址才可以控制我們的代幣，所以這題的攻擊流程如下：  
  1. **授權**給攻擊合約:  
  `approve(address(attacker), 1000000 * (10**18))`
  2. 使用**授權轉帳**把我們錢包的代幣轉出：  `transferFrom(me, address(attacker), 1000000 * (10**18)`  
  p.s. 我的攻擊合約就是關卡合約實例本身 😆