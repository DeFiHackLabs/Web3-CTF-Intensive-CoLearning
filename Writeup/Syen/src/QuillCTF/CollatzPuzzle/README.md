## CollatzPuzzle

### 目标

成功调用 `cft` 函数

### 分析

在 `cft` 函数内, 要求传入的 `addr` 合约字节码是不大于 32 字节。

合约调用本质上是传入字节码给 EVM 执行。合约部署亦同理。

故只要构建出满足条件的合约部署字节码即可。

合约的字节码分为:

- Creation Bytecode 构造函数代码
- Runtime Bytecode 运行时字节码, 包括合约函数。

部署时会将 Creation Bytecode + Runtime Bytecode 发送到节点

1. Runtime Bytecode

分析 `collatzIteration` 代码，传入参数 `n` 为偶数则返回 `n / 2`, 为奇数返回 `3 * n + 1`

`cft` 函数中变量 `q` 由我们的合约方法 `collatzIteration` 计算, 每轮循环中 `q` 的计算结果需等于 `p`

当调用我们的合约后, 传入 `calldata` 数据后, 开始运行 `Runtime Bytecode`

以 `60043580` 开头表示 从内存 0x04 位置读取 32 字节参数的数据入栈(前 4 个自己是方法签名, 后 32 字节是参数 => `q` 是 `uint256` 即 32 字节)

```
PUSH1 0x04 // 0x04 入栈
CALLDATALOAD // 从 0x04 处加载参数 q, 并入栈
DUP1 // 复制到栈顶
```

此时的栈中有两个元素都是参数 `q`

```
PUSH1 0x01 // 0x01 入栈
AND // 出栈 q 和 0x01 并进行按位与(结果为1则 q 是奇数), 并将 q & 0x01 运算结果入栈
PUSH1 0x10 // 0x10 入栈
JUMPI // 出栈 0x10 和 q & 0x01 运算结果, 如果 q & 0x01 结果不为 0(奇数), 则跳转到 0x10

PUSH1 0x01 // 0x01 入栈
SHR // 出栈两个元素进行右移运算, 即运算 q / 2
PUSH1 0x17 // 0x17入栈
JUMP // 出栈 0x17 并跳转到 0x17
JUMPDEST // 跳转标记, 从开始运行到这里刚好 16字节(0x10), 正好对应 JUMPI 跳转位置

PUSH1 0x03 // 0x03 入栈
MUL // 出栈 0x03 和 q 进行 乘法运算, 并将结果入栈
PUSH1 0x01 // 0x01 入栈
ADD // 出栈 0x01 和 乘法结果, 进行相加
JUMPDEST // 跳转标记 位置为 0x17

PUSH1 0x80 // 0x80入栈
MSTORE // 出栈两个元素, 从 0x80 处写入运算结果到内存
PUSH1 0x20 // 0x20 入栈
PUSH1 0x80 // 0x80 入栈
RETURN // 从内存的 0x80 读取 0x20 字节数据返回
```

最终的 Runtime Bytecode 为

```
6004358060011660105760011c6017565b6003026001015b60805260206080f3
```

2. Creation Bytecode

`6020600c60003960206000f3` (12 字节)

```
PUSH1 0x20   // 0x20 入栈 (10 进制 32)
PUSH1 0x0c   // 运行时代码在 Bytecode 中的偏移量为 0x0c(10 进制 12)
PUSH1 0x00   // 目标内存位置
CODECOPY     // 将运行时代码复制到内存(从 Bytecode 的 0x0c 处读取 0x20 个字节写入内存 0x00 处)
PUSH1 0x20   // 要返回的数据长度
PUSH1 0x00   // 内存中数据的起始位置
RETURN       // 返回运行时代码(从内存的0x00读取0x20字节数据返回)
```

合约字节码为:

```
6020600c60003960206000f36004358060011660105760011c6017565b6003026001015b60805260206080f3
```

### POC

```solidity
contract CollatzPuzzleTest is Test {
    CollatzPuzzle public collatzPuzzle;
    address public deployer;

    address public bytecodeAddr;

    function setUp() public {
        deployer = vm.addr(1);

        vm.startPrank(deployer);
        collatzPuzzle = new CollatzPuzzle();

        bytes
            memory bytecode = hex"6020600c60003960206000f36004358060011660105760011c6017565b6003026001015b60805260206080f3";
        address addr;
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "Deployment Failed");

        bytecodeAddr = addr;

        vm.stopPrank();
    }

    function testCallCTF() public {
        vm.prank(deployer);
        bool res = collatzPuzzle.ctf(bytecodeAddr);

        assertEq(res, true);
    }
}

```
