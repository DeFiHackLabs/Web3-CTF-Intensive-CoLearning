// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {AuthorizedExecutor} from "./AuthorizedExecutor.sol";

contract SelfAuthorizedVault is AuthorizedExecutor {
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp = block.timestamp;

    error TargetNotAllowed();
    error CallerNotAllowed();
    error InvalidWithdrawalAmount();
    error WithdrawalWaitingPeriodNotEnded();

    modifier onlyThis() {
        if (msg.sender != address(this)) {
            revert CallerNotAllowed();
        }
        _;
    }

    /**
     * @notice Allows to send a limited amount of tokens to a recipient every now and then
     * @param token address of the token to withdraw
     * @param recipient address of the tokens' recipient
     * @param amount amount of tokens to be transferred
     */
    function withdraw(address token, address recipient, uint256 amount) external onlyThis {
        if (amount > WITHDRAWAL_LIMIT) {
            revert InvalidWithdrawalAmount();
        }

        if (block.timestamp <= _lastWithdrawalTimestamp + WAITING_PERIOD) {
            revert WithdrawalWaitingPeriodNotEnded();
        }

        _lastWithdrawalTimestamp = block.timestamp;

        SafeTransferLib.safeTransfer(token, recipient, amount);
    }

    function sweepFunds(address receiver, IERC20 token) external onlyThis {
        SafeTransferLib.safeTransfer(address(token), receiver, token.balanceOf(address(this)));
    }

    function getLastWithdrawalTimestamp() external view returns (uint256) {
        return _lastWithdrawalTimestamp;
    }

    function _beforeFunctionCall(address target, bytes memory) internal view override {
        if (target != address(this)) {
            revert TargetNotAllowed();
        }
    }
}
