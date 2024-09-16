题目通过字节码字面量部署了合约。在 https://app.dedaub.com/decompile 反编译，可以得到伪 solidity 代码。其中主要逻辑代码为

```solidity
    v0 = v1 = 0;
    while (v0 <= uint8.max) {
        if (MEM[64 + (v0 << 5)]) {
            require(v0 <= uint8.max);
            if (MEM[64 + (v0 << 5)] ^ 0x1) {
                require(v0 <= uint8.max);
                if (!(MEM[64 + (v0 << 5)] ^ 0x2)) {
                    require(MEM[16448] <= int8.max);
                    require(!(MEM[8256 + (MEM[16448] << 5)] + 1 >> 8));
                    MEM[8256 + (MEM[16448] << 5)] = MEM[8256 + (MEM[16448] << 5)] + 1;
                }
            } else {
                require(MEM[16448] - 2 <= MEM[16448]);
                MEM[16448] = MEM[16448] - 2;
            }
        } else {
            require(MEM[16448] + 3 >= MEM[16448]);
            MEM[16448] = MEM[16448] + 3;
        }
        v0 += 1;
        if (!(v0 ^ 0x100)) {
            require(!MEM[16448]);
            v2 = v3 = 0;
            while (v2 <= int8.max) {
                if (MEM[8256 + (v2 << 5)]) {
                    require(v2 <= int8.max);
                    if (MEM[8256 + (v2 << 5)] ^ 0x1) {
                        require(v2 <= int8.max);
                        if (!(MEM[8256 + (v2 << 5)] ^ 0x2)) {
                            require(MEM[16448] <= int8.max);
                            require(!(MEM[12352 + (MEM[16448] << 5)] + 1 >> 8));
                            MEM[12352 + (MEM[16448] << 5)] = MEM[12352 + (MEM[16448] << 5)] + 1;
                        }
                    } else {
                        require(MEM[16448] - 2 <= MEM[16448]);
                        MEM[16448] = MEM[16448] - 2;
                    }
                } else {
                    require(MEM[16448] + 3 >= MEM[16448]);
                    MEM[16448] = MEM[16448] + 3;
                }
                v2 += 1;
                if (!(v2 ^ 0x80)) {
                    if (MEM[0x3040] ^ 0x1) {
                        v4 = v5 = 0;
                    } else if (MEM[0x3060] ^ 0x3) {
                        v4 = v6 = 0;
                    } else if (MEM[0x3080] ^ 0x3) {
                        v4 = v7 = 0;
                    } else {
                        v4 = v8 = !(MEM[0x30a0] ^ 0x7);
                    }
                    require(v4);
                    exit;
                }
            }
            revert();
        }
    }
```

这是一个类似图灵机的计算模型，有三种操作

```
0x00: 指针向右移动 3
0x01: 指针向左移动 2
0x02: 指针位置的值 +1
```

合约会先对输入进行一轮运算，再将结果作为指令进行第二轮运算，最后比较结果。还需要第一轮运算结束后指针指向初始位置。结果满足要求就可以通过。

由于对指令长度的限制不太严格，直接通过 `0x00` 和 `0x01` 每次移动一格并使用若干个 `0x02` 填值即可。可以使用 python 输出 solidity 语句。

```python
def gen(target, end=False):
    l = len(target)
    pos = 0
    now = [0] * l
    res = []

    while pos < l:
        while target[pos] != now[pos]:
            res.append(2)
            now[pos] += 1
        res.append(0)
        res.append(1)
        pos += 1
    if end:
        if pos % 2 != 0:
            pos += 3
            res.append(0)
        while pos > 0:
            pos -= 2
            res.append(1)
    return res

target = [1, 3, 3, 7]

res = gen(gen(target),end=True)
print(len(res))
for i in res:
    print(f"        secret = bytes.concat(secret, bytes32(uint256({i})));")
```

最后的 solidity 代码如下，在末尾填充 `0x06` 作为 nop，达到长度要求

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "./utils/BaseTest.sol";
import "./utils/Utilities.sol";
import "src/Challenge.sol";

contract TestSolver is BaseTest {
    Challenge private challenge;

    constructor() {
    }

    function setupChallenge() public {
        challenge = new Challenge(player);
    }

    function run() public {
        setupChallenge();
        vm.startPrank(player, player);

        bytes memory secret = hex"70d496b9";
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(2)));
        secret = bytes.concat(secret, bytes32(uint256(0)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));
        secret = bytes.concat(secret, bytes32(uint256(1)));

        for(uint i = 0; i < 256 - 87; i++ ) {
            secret = bytes.concat(secret, bytes32(uint256(0x06)));
        }
        challenge.solve(secret);
        assertTrue(challenge.isSolved(), "Not solved.");
        vm.stopPrank();
    }

    function testSolve() public {
        run();
    }
}
```

