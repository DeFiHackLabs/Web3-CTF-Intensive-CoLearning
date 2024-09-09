漏洞点是通过调用 LGT 的 transfer，进入 delegateTransfer，可以转走 DET。可以通过检查调用者是否为 cryptoVault 阻止从 cryptoVault 中转出 DET。事实上由于 `validateInstance` 函数只做了非常简单的检测，怎么写都能通过。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/DoubleEntryPoint.sol";
import "src/levels/DoubleEntryPointFactory.sol";

contract TestDoubleEntryPoint is BaseTest {
    DoubleEntryPoint private level;

    constructor() public {
        levelFactory = new DoubleEntryPointFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = DoubleEntryPoint(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        DetectionBot bot = new DetectionBot(level.cryptoVault());
        level.forta().setDetectionBot(address(bot));

        vm.stopPrank();
    }
}

contract DetectionBot is IDetectionBot {
    address private addr;

    constructor(address _addr) public {
        addr = _addr;
    }

    function handleTransaction(address user, bytes calldata msgData) external override {
        (, , address origSender) = abi.decode(msgData[4:], (address, uint256, address));

        if (origSender == addr) {
            IForta(msg.sender).raiseAlert(user);
        }
    }
}
```

