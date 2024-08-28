// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {WBC, WBCBase} from "src/WBC/WBC.sol";
import {Ans} from "src/WBC/Ans.sol";

contract WBCTest is Test {
    WBCBase public base;
    WBC public wbc;
    Ans public ans;

    uint256 count;

    function setUp() external {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;
        base = new WBCBase(startTime, endTime, fullScore);
        base.setup();
        wbc = base.wbc();
    }

    function testExploit() external {
        // Exploit should be implemented here...

        base.solve();
        assertTrue(base.isSolved());
    }

    function testCannotHomeRunEasily() external {
        vm.expectRevert("try again");
        wbc.homerun();
        vm.expectRevert();
        base.solve();
    }

    function testSalt() external {
        uint256 salt;

        for (uint256 i = 0; i < 1000; ++i) {
            try new Ans{salt: bytes32(i)}(address(wbc)) returns (Ans) {
                salt = i;
                break;
            } catch {}
        }
        console2.log(salt);
    }
}
