---
timezone: Asia/Tokyo
---

# {你的名字}

1. 自我介绍
   [Joy] Web3 前端開發工程師

2. 你认为你会完成本次残酷学习吗？
   初次接觸，盡力完成。

## Notes

<!-- Content_START -->

### 2024.08.29

#### 1. Hello Ethernaut

合約解析入參：keccak256(abi.encodePacked(param))

記錄問題：

1. await contract.password() 沒到到方法在哪

```solidity
   constructor(string memory _password) {
        password = _password;
    }
```


### 2024.08.30
做第二題的時候發現需要Solidity基礎，臨時調整計劃，先學2天入門基礎再做第二題。


#### 筆記
- [學習網址](https://www.wtf.academy/docs/solidity-101/HelloWeb3/)
- [Remix](https://remix.ethereum.org/)

### 2024.09.01

- 值類型

  - 佈爾型
    - 邏輯運算符
      - ! && == !=
      -
      -
  - 整型
    - 正整數、負整數
    - 比較運算符
      - <= < == != >= >
    - 算數運算符
      - - - - / % \*\*
  - 地址類型
    - 普通地址 address
    - payable address (transfer、 send)
  - 定長字節數組
    - 定長字節數組
      - 值類型（bytes1，bytes8，bytes32） 最長 32
    - 不定長字節數組
      - 引用類型
  - 枚舉類型 enum

  ```solidity
     enum ActionSet { Buy, Hold, Sell }

     ActionSet action = ActionSet.Buy;

     function enumToUint() external view returns(uint){
         return uint(action);
      }
  ```


<!-- Content_END -->
