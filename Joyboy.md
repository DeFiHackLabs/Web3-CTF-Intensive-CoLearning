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

### 2024.09.02

- 函數
```solidity

function <function name>(<parameter types>) {internal|external|public|private} [pure|view|payable] [returns (<return types>)]

```

function：声明函数时的固定用法。要编写函数，就需要以 function 关键字开头。

<function name>：函数名。

(<parameter types>)：圆括号内写入函数的参数，即输入到函数的变量类型和名称。

{internal|external|public|private}：函数可见性说明符，共有4种。

public：内部和外部均可见。
private：只能从本合约内部访问，继承的合约也不能使用。
external：只能从合约外部访问（但内部可以通过 this.f() 来调用，f是函数名）。
internal: 只能从合约内部访问，继承的合约可以用。
注意 1：合约中定义的函数需要明确指定可见性，它们没有默认值。

注意 2：public|private|internal 也可用于修饰状态变量。public变量会自动生成同名的getter函数，用于查询数值。未标明可见性类型的状态变量，默认为internal。

[pure|view|payable]：决定函数权限/功能的关键字。payable（可支付的）很好理解，带着它的函数，运行的时候可以给合约转入 ETH。pure 和 view 的介绍见下一节。

[returns ()]：函数返回的变量类型和名称。


<!-- Content_END -->
