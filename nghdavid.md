---
timezone: Asia/Taipei
---


---

# {nghdavid}

1. 自我介绍: 我是比特之神，目前是Web2工程師，想轉職智能合約工程師
2. 你认为你会完成本次残酷学习吗？ 我沒信心XD

## Notes

<!-- Content_START -->

### 2024.08.29

## Foundry指令

### Initialize project
forge init PROJECTNAME

### Install OpenZeppelin
forge install OpenZeppelin/openzeppelin-contracts

### Remappings
forge remappings > remappings.txt

### 指定test
forge test --match-contract HelloWorldTest

### 指定test file
forge test --match-path test/Hello.t.sol

### 有更多解釋
forge test -vvv

### 看gas
forge test --gas-report

### Remapping
forge remappings

### Update library
forge update lib/solmate

### Remove library
forge remove solmate

### Format
forge fmt


### 2024.08.31
# UUPS

### 代理合约

代理合约的變量

- 邏輯合約地址
- admin地址
- 字符串: 可透過邏輯合約的函數改變

代理合约的函數

- constructor: Initialize邏輯合約地址與admin地址
- fallback: delegatecall邏輯合約

```jsx
contract UUPSProxy {
    address public implementation; // 逻辑合约地址
    address public admin; // admin地址
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 构造函数，初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数，将调用委托给逻辑合约
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
}
```

### 邏輯合約

升級函數放在邏輯合約: upgrade() ⇒ 只能由admin調用

改變代理合約的狀態的函數

```jsx
// UUPS逻辑合约（升级函数写在逻辑合约内）
contract UUPS1{
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器： 0xc2985578
    function foo() public{
        words = "old";
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用。选择器：0x0900f010
    // UUPS中，逻辑合约中必须包含升级函数，不然就不能再升级了。
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

// 新的UUPS逻辑合约
contract UUPS2{
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器： 0xc2985578
    function foo() public{
        words = "new";
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用。选择器：0x0900f010
    // UUPS中，逻辑合约中必须包含升级函数，不然就不能再升级了。
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```



<!-- Content_END -->
