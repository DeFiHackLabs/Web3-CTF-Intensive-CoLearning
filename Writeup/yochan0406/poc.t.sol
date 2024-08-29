// SPDX-License-Identifier: MIT

// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)

pragma solidity =0.8.25;



import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {UnstoppableVault, Owned} from "../../src/unstoppable/UnstoppableVault.sol";
import {UnstoppableMonitor} from "../../src/unstoppable/UnstoppableMonitor.sol";



contract UnstoppableChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address monitor = makeAddr("monitor");


    uint256 constant TOKENS_IN_VAULT = 1_000_000e18;
    uint256 constant INITIAL_PLAYER_TOKEN_BALANCE = 10e18;



    DamnValuableToken public token;
    UnstoppableVault public vault;
    UnstoppableMonitor public monitorContract;



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
        // Deploy token and vault
        token = new DamnValuableToken();
        vault = new UnstoppableVault({_token: token, _owner: deployer, _feeRecipient: deployer});



        // Deposit tokens to vault
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, address(deployer));



        // Fund player's account with initial token balance
        token.transfer(player, INITIAL_PLAYER_TOKEN_BALANCE);



        // Deploy monitor contract and grant it vault's ownership
        monitorContract = new UnstoppableMonitor(address(vault));
        vault.transferOwnership(address(monitorContract));



        // Monitor checks it's possible to take a flash loan
        vm.expectEmit();
        emit UnstoppableMonitor.FlashLoanStatus(true);
        monitorContract.checkFlashLoan(100e18);



        vm.stopPrank();

    }



    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */

    function test_assertInitialState() public {
        // Check initial token balances
        assertEq(token.balanceOf(address(vault)), TOKENS_IN_VAULT);
        assertEq(token.balanceOf(player), INITIAL_PLAYER_TOKEN_BALANCE);



        // Monitor is owned
        assertEq(monitorContract.owner(), deployer);



        // Check vault properties
        assertEq(address(vault.asset()), address(token));
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        assertEq(vault.maxFlashLoan(address(token)), TOKENS_IN_VAULT);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT - 1), 0);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT), 50000e18);



        // Vault is owned by monitor contract
        assertEq(vault.owner(), address(monitorContract));



        // Vault is not paused
        assertFalse(vault.paused());



        // Cannot pause the vault
        vm.expectRevert("UNAUTHORIZED");
        vault.setPause(true);


        // Cannot call monitor contract
        vm.expectRevert("UNAUTHORIZED");
        monitorContract.checkFlashLoan(100e18);
    }



    /**
     * CODE YOUR SOLUTION HERE
     */

    function test_unstoppable() public {   

        

        // 設置每次借貸的金額（可選擇小於總金額的適當值）
        uint256 amountToBorrow = 100e18;



        // 總共要借出多少次以取出所有金庫資金
        uint256 numLoans = TOKENS_IN_VAULT / amountToBorrow;



        // 進行多次，逐步取出金庫中的資金
        for (uint256 i = 0; i < numLoans; i++) {
            // 每次借貸都應該確保是有效的
            try vault.flashLoan(
                monitorContract, // 使用 monitorContract 作為閃電貸接收者
                address(token),
                amountToBorrow,
                ""
            ) {

                // 如果成功，繼續進行下一步
            } catch {
                // 處理錯誤，例如金庫可能已經被暫停
                break;
            }
        }


        

    }








    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */

    function _isSolved() private {
        // Flashloan check must fail
        vm.prank(deployer);
        vm.expectEmit();
        emit UnstoppableMonitor.FlashLoanStatus(false);
        monitorContract.checkFlashLoan(100e18);


        // And now the monitor paused the vault and transferred ownership to deployer
        assertTrue(vault.paused(), "Vault is not paused");
        assertEq(vault.owner(), deployer, "Vault did not change owner");

    }

}


