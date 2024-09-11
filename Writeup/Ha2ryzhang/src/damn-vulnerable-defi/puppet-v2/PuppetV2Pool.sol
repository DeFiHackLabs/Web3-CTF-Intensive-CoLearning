// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {UniswapV2Library} from "./UniswapV2Library.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract PuppetV2Pool {
    address private _uniswapPair;
    address private _uniswapFactory;
    IERC20 private _token;
    IERC20 private _weth;

    mapping(address => uint256) public deposits;

    event Borrowed(address indexed borrower, uint256 depositRequired, uint256 borrowAmount, uint256 timestamp);

    constructor(address wethAddress, address tokenAddress, address uniswapPairAddress, address uniswapFactoryAddress) {
        _weth = IERC20(wethAddress);
        _token = IERC20(tokenAddress);
        _uniswapPair = uniswapPairAddress;
        _uniswapFactory = uniswapFactoryAddress;
    }

    /**
     * @notice Allows borrowing tokens by first depositing three times their value in WETH
     *         Sender must have approved enough WETH in advance.
     *         Calculations assume that WETH and borrowed token have same amount of decimals.
     */
    function borrow(uint256 borrowAmount) external {
        // Calculate how much WETH the user must deposit
        uint256 amount = calculateDepositOfWETHRequired(borrowAmount);

        // Take the WETH
        _weth.transferFrom(msg.sender, address(this), amount);

        // internal accounting
        deposits[msg.sender] += amount;

        require(_token.transfer(msg.sender, borrowAmount), "Transfer failed");

        emit Borrowed(msg.sender, amount, borrowAmount, block.timestamp);
    }

    function calculateDepositOfWETHRequired(uint256 tokenAmount) public view returns (uint256) {
        uint256 depositFactor = 3;
        return _getOracleQuote(tokenAmount) * depositFactor / 1 ether;
    }

    // Fetch the price from Uniswap v2 using the official libraries
    function _getOracleQuote(uint256 amount) private view returns (uint256) {
        (uint256 reservesWETH, uint256 reservesToken) =
            UniswapV2Library.getReserves({factory: _uniswapFactory, tokenA: address(_weth), tokenB: address(_token)});

        return UniswapV2Library.quote({amountA: amount * 10 ** 18, reserveA: reservesToken, reserveB: reservesWETH});
    }
}
