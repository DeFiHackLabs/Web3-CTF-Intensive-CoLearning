// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TransferHelper} from "@uniswap/v3-core/contracts/libraries/TransferHelper.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

/**
 * @notice A lending pool using Uniswap v3 as TWAP oracle.
 */
contract PuppetV3Pool {
    uint256 public constant DEPOSIT_FACTOR = 3;
    uint32 public constant TWAP_PERIOD = 10 minutes;

    WETH public immutable weth;
    DamnValuableToken public immutable token;
    IUniswapV3Pool public immutable uniswapV3Pool;

    mapping(address => uint256) public deposits;

    event Borrowed(address indexed borrower, uint256 depositAmount, uint256 borrowAmount);

    constructor(WETH _weth, DamnValuableToken _token, IUniswapV3Pool _uniswapV3Pool) {
        weth = _weth;
        token = _token;
        uniswapV3Pool = _uniswapV3Pool;
    }

    /**
     * @notice Allows borrowing `borrowAmount` of tokens by first depositing DEPOSIT_FACTOR times their value in WETH.
     *         Sender must have approved enough WETH in advance.
     *         Calculations assume that WETH and the borrowed token have the same number of decimals.
     * @param borrowAmount amount of tokens the user intends to borrow
     */
    function borrow(uint256 borrowAmount) external {
        // Calculate how much WETH the user must deposit
        uint256 depositOfWETHRequired = calculateDepositOfWETHRequired(borrowAmount);

        //TODO: use Permit2 (0x000000000022D473030F116dDEE9F6B43aC78BA3)

        // Pull WETH from caller
        weth.transferFrom(msg.sender, address(this), depositOfWETHRequired);

        // internal accounting
        deposits[msg.sender] += depositOfWETHRequired;

        // send borrowed tokens
        TransferHelper.safeTransfer(address(token), msg.sender, borrowAmount);

        emit Borrowed(msg.sender, depositOfWETHRequired, borrowAmount);
    }

    function calculateDepositOfWETHRequired(uint256 amount) public view returns (uint256) {
        uint256 quote = _getOracleQuote(_toUint128(amount));
        return quote * DEPOSIT_FACTOR;
    }

    function _getOracleQuote(uint128 amount) private view returns (uint256) {
        (int24 arithmeticMeanTick,) = OracleLibrary.consult({pool: address(uniswapV3Pool), secondsAgo: TWAP_PERIOD});
        return OracleLibrary.getQuoteAtTick({
            tick: arithmeticMeanTick,
            baseAmount: amount,
            baseToken: address(token),
            quoteToken: address(weth)
        });
    }

    function _toUint128(uint256 amount) private pure returns (uint128 n) {
        require(amount == (n = uint128(amount)));
    }
}
