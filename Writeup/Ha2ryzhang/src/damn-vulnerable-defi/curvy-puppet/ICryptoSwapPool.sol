// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

/*
 * Interface for CryptoSwap pools with implementation at `0xa85461AFc2DEEC01bDA23b5cd267d51F765fba10`
 * See https://docs.curve.fi/cryptoswap-exchange/cryptoswap/pools/crypto-pool/
 */
interface ICryptoSwapPool {
    event AddLiquidity(address indexed provider, uint256[2] token_amounts, uint256 fee, uint256 token_supply);
    event ClaimAdminFee(address indexed admin, uint256 tokens);
    event CommitNewParameters(
        uint256 indexed deadline,
        uint256 admin_fee,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 fee_gamma,
        uint256 allowed_extra_profit,
        uint256 adjustment_step,
        uint256 ma_half_time
    );
    event NewParameters(
        uint256 admin_fee,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 fee_gamma,
        uint256 allowed_extra_profit,
        uint256 adjustment_step,
        uint256 ma_half_time
    );
    event RampAgamma(
        uint256 initial_A,
        uint256 future_A,
        uint256 initial_gamma,
        uint256 future_gamma,
        uint256 initial_time,
        uint256 future_time
    );
    event RemoveLiquidity(address indexed provider, uint256[2] token_amounts, uint256 token_supply);
    event RemoveLiquidityOne(address indexed provider, uint256 token_amount, uint256 coin_index, uint256 coin_amount);
    event StopRampA(uint256 current_A, uint256 current_gamma, uint256 time);
    event TokenExchange(
        address indexed buyer, uint256 sold_id, uint256 tokens_sold, uint256 bought_id, uint256 tokens_bought
    );

    fallback() external payable;

    function A() external view returns (uint256);
    function D() external view returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_eth)
        external
        payable
        returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_eth, address receiver)
        external
        payable
        returns (uint256);
    function adjustment_step() external view returns (uint256);
    function admin_actions_deadline() external view returns (uint256);
    function admin_fee() external view returns (uint256);
    function allowed_extra_profit() external view returns (uint256);
    function apply_new_parameters() external;
    function balances(uint256 arg0) external view returns (uint256);
    function calc_token_amount(uint256[2] memory amounts) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);
    function claim_admin_fees() external;
    function coins(uint256 arg0) external view returns (address);
    function commit_new_parameters(
        uint256 _new_mid_fee,
        uint256 _new_out_fee,
        uint256 _new_admin_fee,
        uint256 _new_fee_gamma,
        uint256 _new_allowed_extra_profit,
        uint256 _new_adjustment_step,
        uint256 _new_ma_half_time
    ) external;
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth)
        external
        payable
        returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth, address receiver)
        external
        payable
        returns (uint256);
    function exchange_extended(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address sender,
        address receiver,
        bytes32 cb
    ) external payable returns (uint256);
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy, address receiver)
        external
        payable
        returns (uint256);
    function factory() external view returns (address);
    function fee() external view returns (uint256);
    function fee_gamma() external view returns (uint256);
    function future_A_gamma() external view returns (uint256);
    function future_A_gamma_time() external view returns (uint256);
    function future_adjustment_step() external view returns (uint256);
    function future_admin_fee() external view returns (uint256);
    function future_allowed_extra_profit() external view returns (uint256);
    function future_fee_gamma() external view returns (uint256);
    function future_ma_half_time() external view returns (uint256);
    function future_mid_fee() external view returns (uint256);
    function future_out_fee() external view returns (uint256);
    function gamma() external view returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function initial_A_gamma() external view returns (uint256);
    function initial_A_gamma_time() external view returns (uint256);
    function initialize(
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
        address _token,
        address[2] memory _coins,
        uint256 _precisions
    ) external;
    function last_prices() external view returns (uint256);
    function last_prices_timestamp() external view returns (uint256);
    function lp_price() external view returns (uint256);
    function ma_half_time() external view returns (uint256);
    function mid_fee() external view returns (uint256);
    function out_fee() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function price_scale() external view returns (uint256);
    function ramp_A_gamma(uint256 future_A, uint256 future_gamma, uint256 future_time) external;
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts, bool use_eth) external;
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts, bool use_eth, address receiver)
        external;
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount)
        external
        returns (uint256);
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount, bool use_eth)
        external
        returns (uint256);
    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);
    function revert_new_parameters() external;
    function stop_ramp_A_gamma() external;
    function token() external view returns (address);
    function virtual_price() external view returns (uint256);
    function xcp_profit() external view returns (uint256);
    function xcp_profit_a() external view returns (uint256);
}
