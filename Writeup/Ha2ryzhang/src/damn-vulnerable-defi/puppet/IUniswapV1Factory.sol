// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface IUniswapV1Factory {
    event NewExchange(address indexed token, address indexed exchange);

    function createExchange(address token) external returns (address out);
    function exchangeTemplate() external view returns (address out);
    function getExchange(address token) external view returns (address out);
    function getToken(address exchange) external returns (address out);
    function getTokenWithId(uint256 token_id) external returns (address out);
    function initializeFactory(address template) external;
}
