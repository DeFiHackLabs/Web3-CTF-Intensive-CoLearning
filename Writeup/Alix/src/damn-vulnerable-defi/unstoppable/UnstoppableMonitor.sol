// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {UnstoppableVault, ERC20} from "../unstoppable/UnstoppableVault.sol";

/**
 * @notice Permissioned contract for on-chain monitoring of the vault's flashloan feature.  
 */
contract UnstoppableMonitor is Owned, IERC3156FlashBorrower {
    UnstoppableVault private immutable vault;

    error UnexpectedFlashLoan();

    event FlashLoanStatus(bool success);

    constructor(address _vault) Owned(msg.sender) {
        vault = UnstoppableVault(_vault);
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || fee != 0) {
            revert UnexpectedFlashLoan();
        }

        ERC20(token).approve(address(vault), amount);

        return keccak256("IERC3156FlashBorrower.onFlashLoan");
    }

    function checkFlashLoan(uint256 amount) external onlyOwner {
        require(amount > 0);

        address asset = address(vault.asset());

        try vault.flashLoan(this, asset, amount, bytes("")) {
            emit FlashLoanStatus(true);
        } catch {
            // Something bad happened
            emit FlashLoanStatus(false);

            // Pause the vault
            vault.setPause(true);

            // Transfer ownership to allow review & fixes
            vault.transferOwnership(owner);
        }
    }
}
