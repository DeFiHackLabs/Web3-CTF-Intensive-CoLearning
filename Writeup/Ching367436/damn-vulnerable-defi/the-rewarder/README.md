## [The Rewarder](https://www.damnvulnerabledefi.xyz/challenges/the-rewarder/)

### Analysis

> A contract is distributing rewards of Damn Valuable Tokens and WETH.
>
> To claim rewards, users must prove they’re included in the chosen set of beneficiaries. Don’t worry about gas though. The contract has been optimized and allows claiming multiple tokens in the same transaction.
>
> Alice has claimed her rewards already. You can claim yours too! But you’ve realized there’s a critical vulnerability in the contract.
>
> Save as much funds as you can from the distributor. Transfer all recovered assets to the designated recovery account.

To solve the challenge, we need to drain most of the DVT, WETH tokens from the `distributor` contract.

```solidity
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
```

We need to identify all the places where tokens can be transferred to drain them from the contract. In this case, it's worth investigating the `distributor.clean` function and the `distributor.claimRewards` function because they both use the transfer keyword. The `distributor.clean` function can only transfer tokens to the `owner`, which is not controllable by us, making the function useless to us. Therefore, we should focus on the `distributor.claimRewards` function. This function uses the `_setClaimed` function to prevent the same token from being claimed multiple times. However, there are some flaws in it. First, the `if (address(token) != address(0))` statement will not set the token claim in the first pass of the loop. Second, when the (i+1)-th claim in our `inputClaims.token` is different from the i-th one, it will incorrectly mark the i-th token as claimed instead of the correct (i+1)-th one, allowing us to claim the tokens multiple times.

```solidity
contract TheRewarderDistributor {
  // [...]
  address public immutable owner = msg.sender;
  // [...]
  function clean(IERC20[] calldata tokens) external {
      for (uint256 i = 0; i < tokens.length; i++) {
          IERC20 token = tokens[i];
          if (distributions[token].remaining == 0) {
              token.transfer(owner, token.balanceOf(address(this)));
          }
      }
  }
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
  // [...]
}
```

### Solution
See [TheRewarder.t.sol](./TheRewarder.t.sol#L150).