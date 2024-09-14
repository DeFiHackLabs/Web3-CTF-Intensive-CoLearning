运行时逻辑是返回 42

```yul
object "runtime" {
    code {
        mstore(0, 42)
        return (0, 32)
    }
}
```

合约初始化代码将上述代码的字节码复制到内存后 `RETURN` 即可

```yul
object "Contract" {
    // This is the constructor code of the contract.
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            mstore(0, 42)
            return (0, 32)
        }
    }
}
```

可以在 https://www.evm.codes/playground 验证字节码的运行效果。

最后使用 `create` 调用该字节码创建合约即可。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/MagicNum.sol";
import "src/levels/MagicNumFactory.sol";

contract TestMagicNum is BaseTest {
    MagicNum private level;

    constructor() public {
        levelFactory = new MagicNumFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = MagicNum(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        bytes memory bytecode = hex"600a600d600039600a6000f3fe602a60005260206000f3";

        address solverInstance;

        assembly{
            solverInstance := create(0, add(bytecode, 0x20),  mload(bytecode))
        }

        level.setSolver(solverInstance);

        vm.stopPrank();
    }
}
```

