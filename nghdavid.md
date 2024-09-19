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

### 2024.09.05
# Ethernut第二題
- 在舊版的solidity, Constructor不是Contructor(), 而是合約名稱
- 這題的合約的Constructor有typo => Fal1out
- 因此該合約的Constructor為空的
- 可以直接呼叫Fal1out將owner改為自己

### 2024.09.07
# Ethernut第三題
- 合約中使用的 flip()函式作為擲硬幣的動作，需要執行十次且每次都要 reture True 才算通關。
- blockValue是決定硬幣正反面的關鍵變數，blockValue為blockhash(block.number—1)
- block.number這個值是deterministic, 所以可以寫合約來做攻擊
- 攻擊的原理是對當下被打包的區塊的number去做計算(blockValue/FACTOR) == 1
- 這樣就能精準猜中flip side

### 2024.09.09
# Ethernut第四題
- 這題的關鍵是要能成功呼叫changeOwner
- 所以要使tx.origin跟msg.sender不一樣
- 如果使用合約呼叫changeOwner，這樣tx.origin就會是自己(EOA)，而msg.sender會是合約本身
- 如此一來就能達到tx.origin != msg.sender，而成功改變owner

### 2024.09.10
# Ethernut第五題
- 這題的關鍵是使用overflow來使自己的balance變成很大
- 因為Token的合約定義每個人有20個幣
- 所以只要對Token呼叫transfer(otherAddress, 21)即可
- 這樣require(balances[msg.sender] — _value >= 0)會因為overflow通過檢查
- 而balances[msg.sender] -= _value會因為overflow變成超大的值(2²⁵⁶ - 1)

### 2024.09.12
# Ethernut第六題
- 對Delegation呼叫且msg.data是帶abi.encodeWithSignature("pwn()")
- 因為Delegation沒有對應的function selector，所以會掉到fallback function裏面
- fallback function裡的address(delegate).delegatecall(msg.data)會成address(delegate).delegatecall(abi.encodeWithSignature("pwn()”)）
- 因此Delegate合約的pwn()會被執行(delegate call)，造成Delegation的owner會變成你的address
- 在delegate call下，msg.sender會是你，而不是Delegation的地址

### 2024.09.13
# Ethernut第七題
- The goal is to make balance > 0
- 因為該合約沒有任何receive與callback function
- 所以無法打Eth給這個合約
- 唯一的辦法是讓其他合約selfdestruct強制將其他合約的Eth轉給該合約
- 所以就是創建一個合約，讓這個合約執行selfdestruct，指定該合約的地址為參數

### 2024.09.16
# Ethernut第八題
- 這題的關鍵是找到被設為private的password
- 然後使用unlock()把鎖打開
- 因爲private的關係，要透過storage slot找到password，使用foundry裡的vm.load去讀取
- locked為bool，大小為一個byte，佔據slot 0
- password為bytes32，大小為32byte，因為放不下slot 0，所以放在slot 1
- 故使用vm.load(address, bytes32(uint256(1)))去讀取slot 1的password
- 最後再輸入正確的密碼去用unlock去解鎖

### 2024.09.18
# Ethernut第九題
- 這題的關鍵是要讓挑戰合約的receive()裡的payable(king).transfer(msg.value)出現revert
- 以至於讓整個receive()不能執行
- 首先要設立一個合約，有一個function要轉0.001Eth到挑戰合約，以成為King
- 接著這個合約的receive()要針對挑戰合約的地址去revert
- 如此一來別人無法再成功呼叫挑戰合約的receive()，別人也就無法成為king了



<!-- Content_END -->
