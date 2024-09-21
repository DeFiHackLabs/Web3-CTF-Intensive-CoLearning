// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {HelloWorld,HelloWorldBase} from "src/HelloWorld.sol";

contract HelloWorld_POC is Test {
    HelloWorld _helloworld;
    HelloWorldBase _helloworldbase;
    function init() private{
        vm.startPrank(address(0x10));
        _helloworldbase = new HelloWorldBase(block.timestamp+1, block.timestamp+2, 0);
        _helloworldbase.setup();
        _helloworld = _helloworldbase.helloWorld();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_HelloWorld_POC() public{
        _helloworld.answer("HelloWorld");
        _helloworldbase.solve();
        console.log("Success: ",_helloworldbase.isSolved());
    }
        
}
