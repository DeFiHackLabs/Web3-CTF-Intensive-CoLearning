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

### 2024.09.02
# Transparent Proxy
### 代理合约
代理合约的變量

- 邏輯合約地址
- admin地址
- 字符串: 可透過邏輯合約的函數改變

代理合约的函數
- constructor: Initialize邏輯合約地址與admin地址
- fallback: delegatecall邏輯合約，admin不能調用
- upgrade: 改變邏輯合約地址，只能由admin調用

透過權限管理避免function selector collision

```jsx

// 透明可升级合约的教学代码，不要用于生产。
contract TransparentProxy {
    address implementation; // logic合约地址
    address admin; // 管理员
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 构造函数，初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数，将调用委托给逻辑合约
    // 不能被admin调用，避免选择器冲突引发意外
    fallback() external payable {
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
}
```

### 邏輯合約
邏輯合約的變量(變數位置需與代理合约的位置一樣，防止storage collision)

- 邏輯合約地址
- admin地址
- 字符串: 可透過邏輯合約的函數改變

```jsx

// 旧逻辑合约
contract Logic1 {
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器： 0xc2985578
    function foo() public{
        words = "old";
    }
}

// 新逻辑合约
contract Logic2 {
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation;
    address public admin; 
    string public words; // 字符串，可以通过逻辑合约的函数改变

    // 改变proxy中状态变量，选择器：0xc2985578
    function foo() public{
        words = "new";
    }
}
```
### UUPS與Transparent Proxy的差別
- UUPS => 升級函數放在邏輯合約(較複雜)
- Transparent Proxy => 升級函數放在代理合約(耗gas)

### UUPS與Transparent Proxy的目的
- 解決function selector collision

### 2024.09.03
# How to prevent reentrancy attack
### 使用重入鎖
重入鎖是一種重入函數的modifier，包含一開始是0的狀態變量(_status)，一開始檢查_status是否為0，接著馬上把_status改為1，等最後結束後才把_status改為0。這樣攻擊合約一定要等調用結束才能再發起第二次的調用。也因此重入攻擊無法成功。

```jsx
uint256 private _status; // 重入锁

// 重入锁
modifier nonReentrant() {
    // 在第一次调用 nonReentrant 时，_status 将是 0
    require(_status == 0, "ReentrancyGuard: reentrant call");
    // 在此之后对 nonReentrant 的任何调用都将失败
    _status = 1;
    _;
    // 调用结束，将 _status 恢复为0
    _status = 0;
}
```
### Openzeppelin code

[OpenZeppelin ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/utils/ReentrancyGuard.sol)

```jsx
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    // 重入鎖在這裡
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}
```
### Checks-effect-interaction
1. 檢查狀態變量
2. 馬上更新狀態變量
3. 再把錢給別人

### 2024.09.04
# Ethernut第一題
1. 呼叫contribute，讓contributions[my address]有值
2. Send Ether到Fallback合約觸發receive()，讓自己變owner
3. 呼叫withdraw()，抽走所有Ether

<!-- Content_END -->
