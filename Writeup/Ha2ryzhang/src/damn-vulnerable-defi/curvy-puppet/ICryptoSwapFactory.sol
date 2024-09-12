// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

/*
 * Interface for CryptoSwap Factory at `0xF18056Bbd320E96A48e3Fbf8bC061322531aac99`
 * See https://docs.curve.fi/factory/cryptoswap/overview/
 */
interface ICryptoSwapFactory {
    event CryptoPoolDeployed(
        address token,
        address[2] coins,
        uint256 A,
        uint256 gamma,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 allowed_extra_profit,
        uint256 fee_gamma,
        uint256 adjustment_step,
        uint256 admin_fee,
        uint256 ma_half_time,
        uint256 initial_price,
        address deployer
    );
    event LiquidityGaugeDeployed(address pool, address token, address gauge);
    event TransferOwnership(address _old_owner, address _new_owner);
    event UpdateFeeReceiver(address _old_fee_receiver, address _new_fee_receiver);
    event UpdateGaugeImplementation(address _old_gauge_implementation, address _new_gauge_implementation);
    event UpdatePoolImplementation(address _old_pool_implementation, address _new_pool_implementation);
    event UpdateTokenImplementation(address _old_token_implementation, address _new_token_implementation);

    function accept_transfer_ownership() external;
    function admin() external view returns (address);
    function commit_transfer_ownership(address _addr) external;
    function deploy_gauge(address _pool) external returns (address);
    function deploy_pool(
        string memory _name,
        string memory _symbol,
        address[2] memory _coins,
        uint256 A,
        uint256 gamma,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 allowed_extra_profit,
        uint256 fee_gamma,
        uint256 adjustment_step,
        uint256 admin_fee,
        uint256 ma_half_time,
        uint256 initial_price
    ) external returns (address);
    function fee_receiver() external view returns (address);
    function find_pool_for_coins(address _from, address _to) external view returns (address);
    function find_pool_for_coins(address _from, address _to, uint256 i) external view returns (address);
    function future_admin() external view returns (address);
    function gauge_implementation() external view returns (address);
    function get_balances(address _pool) external view returns (uint256[2] memory);
    function get_coin_indices(address _pool, address _from, address _to) external view returns (uint256, uint256);
    function get_coins(address _pool) external view returns (address[2] memory);
    function get_decimals(address _pool) external view returns (uint256[2] memory);
    function get_eth_index(address _pool) external view returns (uint256);
    function get_gauge(address _pool) external view returns (address);
    function get_token(address _pool) external view returns (address);
    function pool_count() external view returns (uint256);
    function pool_implementation() external view returns (address);
    function pool_list(uint256 arg0) external view returns (address);
    function set_fee_receiver(address _fee_receiver) external;
    function set_gauge_implementation(address _gauge_implementation) external;
    function set_pool_implementation(address _pool_implementation) external;
    function set_token_implementation(address _token_implementation) external;
    function token_implementation() external view returns (address);
}
