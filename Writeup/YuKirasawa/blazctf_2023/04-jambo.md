通过字节码字面量部署合约。在 https://app.dedaub.com/decompile 反编译，可以得到伪 solidity 代码。其中可以提取代币的逻辑代码为 `answer` 函数

```solidity
        if (function_selector >> 224 == 0x2f484947) {
            require(msg.data.length - 4 >= 32);
            require(varg1 <= uint64.max);
            require(4 + varg1 + 31 < msg.data.length);
            require(varg1.length <= uint64.max, Panic(65)); // failed memory allocation (too much memory)
            v1 = new bytes[](varg1.length);
            0x149(v1, (varg1.length + 31 & ~0x1f) + 32);
            require(varg1.data + varg1.length <= msg.data.length);
            CALLDATACOPY(v1.data, varg1.data, varg1.length);
            v1[varg1.length] = 0;
            v2 = v1.length;
            v3 = v1.data;
            v4 = v5 = stor_1 == keccak256(v1);
            if (v5) {
                v4 = msg.value > 10 ** 18;
            }
            if (v4) {
                v6 = 0x617(msg.sender);
                v7 = 0x617(v6);
                v8 = 0x617(this);
                v9 = v10 = 0;
                if (!v8.balance) {
                    v9 = v11 = 2300;
                }
                v12 = v7.call().value(v8.balance).gas(v9);
                require(v12, MEM[64], RETURNDATASIZE());
                require(msg.sender.code.size == 0);
            }
            return ;
        }
```

其中需要满足 `stor_1 == keccak256(v1);`，并发送超过 1 ether 的代币。`stor_1` 可以在 `start` 函数中修改

```solidity
        if (function_selector >> 224 == 0xf5b938e2) {
            require(msg.data.length - 4 >= 64);
            if ((keccak256(msg.sender) >> 248) - 55) {
                ___function_selector__ = ___function_selector__ & ~0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff | varg1;
                0x149(MEM[64], 64);
                stor_1 = stor_1 & ~0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff | uint256(keccak256(varg2));
                0x149(MEM[64], 52);
                v13 = 0x501(1);
                require(STORAGE[keccak256(msg.sender)] == v13);
            }
            return ;
        }
```

因此直接使用 setup 时传入 `start` 的参数就可以通过检查。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "./utils/BaseTest.sol";
import "./utils/Utilities.sol";
import "src/Challenge.sol";

// interface Jambo {
//     function answer(bytes memory _answer) external payable;
//     function start(uint256 qid, bytes32 _answer) external payable;
//     function revokeOwnership() external;
// }
//
contract TestSolver is BaseTest {
    Challenge private chal;

    constructor() {
    }

    function setupChallenge() public {
        chal = new Challenge{value: 25 ether}();
    }

    function run() public {
        setupChallenge();
        vm.startPrank(player, player);

        Jambo(chal.target()).answer{value:1.1 ether}(abi.encodePacked(bytes32(0x66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64)));

        assertTrue(chal.isSolved(), "Not solved.");
        vm.stopPrank();
    }

    function testSolve() public {
        run();
    }
}
```

