// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {IStableSwap} from "./IStableSwap.sol";
import {CurvyPuppetOracle} from "./CurvyPuppetOracle.sol";
import {console} from "forge-std/console.sol";

contract CurvyPuppetLending is ReentrancyGuard {
    using FixedPointMathLib for uint256;

    address public immutable borrowAsset;
    address public immutable collateralAsset;
    IStableSwap public immutable curvePool;
    IPermit2 public immutable permit2;
    CurvyPuppetOracle public immutable oracle;

    struct Position {
        uint256 collateralAmount;
        uint256 borrowAmount;
    }

    mapping(address who => Position) public positions;

    error InvalidAmount();
    error NotEnoughCollateral();
    error HealthyPosition(uint256 borrowValue, uint256 collateralValue);
    error UnhealthyPosition();

    constructor(address _collateralAsset, IStableSwap _curvePool, IPermit2 _permit2, CurvyPuppetOracle _oracle) {
        borrowAsset = _curvePool.lp_token();
        collateralAsset = _collateralAsset;
        curvePool = _curvePool;
        permit2 = _permit2;
        oracle = _oracle;
    }

    function deposit(uint256 amount) external nonReentrant {
        positions[msg.sender].collateralAmount += amount;
        _pullAssets(collateralAsset, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        uint256 remainingCollateral = positions[msg.sender].collateralAmount - amount;
        uint256 remainingCollateralValue = getCollateralValue(remainingCollateral);
        uint256 borrowValue = getBorrowValue(positions[msg.sender].borrowAmount);

        if (borrowValue * 175 > remainingCollateralValue * 100) revert UnhealthyPosition();

        positions[msg.sender].collateralAmount = remainingCollateral;
        IERC20(collateralAsset).transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        // Get current collateral and borrow values
        uint256 collateralValue = getCollateralValue(positions[msg.sender].collateralAmount);
        uint256 currentBorrowValue = getBorrowValue(positions[msg.sender].borrowAmount);

        uint256 maxBorrowValue = collateralValue * 100 / 175;
        uint256 availableBorrowValue = maxBorrowValue - currentBorrowValue;

        if (amount == type(uint256).max) {
            // set amount to as much borrow tokens as possible, given the available borrow value and the borrow asset's price
            amount = availableBorrowValue.divWadDown(_getLPTokenPrice());
        }

        if (amount == 0) revert InvalidAmount();

        // Now do solvency check
        uint256 borrowAmountValue = getBorrowValue(amount);
        if (currentBorrowValue + borrowAmountValue > maxBorrowValue) revert NotEnoughCollateral();

        // Update caller's position and transfer borrowed assets
        positions[msg.sender].borrowAmount += amount;
        IERC20(borrowAsset).transfer(msg.sender, amount);
    }

    function redeem(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        positions[msg.sender].borrowAmount -= amount;
        _pullAssets(borrowAsset, amount);

        if (positions[msg.sender].borrowAmount == 0) {
            uint256 returnAmount = positions[msg.sender].collateralAmount;
            positions[msg.sender].collateralAmount = 0;
            IERC20(collateralAsset).transfer(msg.sender, returnAmount);
        }
    }

    function liquidate(address target) external nonReentrant {
        uint256 borrowAmount = positions[target].borrowAmount;
        uint256 collateralAmount = positions[target].collateralAmount;

        uint256 collateralValue = getCollateralValue(collateralAmount) * 100;
        uint256 borrowValue = getBorrowValue(borrowAmount) * 175;
        if (collateralValue >= borrowValue) revert HealthyPosition(borrowValue, collateralValue);

        delete positions[target];

        _pullAssets(borrowAsset, borrowAmount);
        IERC20(collateralAsset).transfer(msg.sender, collateralAmount);
    }

    function getBorrowValue(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;
        return amount.mulWadUp(_getLPTokenPrice());
    }

    function getCollateralValue(uint256 amount) public view returns (uint256) {
        if (amount == 0) return 0;
        return amount.mulWadDown(oracle.getPrice(collateralAsset).value);
    }

    function getBorrowAmount(address who) external view returns (uint256) {
        return positions[who].borrowAmount;
    }

    function getCollateralAmount(address who) external view returns (uint256) {
        return positions[who].collateralAmount;
    }

    function _pullAssets(address asset, uint256 amount) private {
        permit2.transferFrom({from: msg.sender, to: address(this), amount: SafeCast.toUint160(amount), token: asset});
    }

    function _getLPTokenPrice() private view returns (uint256) {
        return oracle.getPrice(curvePool.coins(0)).value.mulWadDown(curvePool.get_virtual_price());
    }
}
