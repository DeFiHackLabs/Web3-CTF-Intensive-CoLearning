## Unstoppable
### Analysis

In this challenge, we need to make the `UnstoppableVault.flashLoan` reverts, so we started by looking for all the places that use the `revert` function when calling the `flashLoan` function. 

```solidity
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
```

The `flashLoan` function in the `UnstoppableVault` contract is called when the `monitorContract.checkFlashLoan` function is invoked. The 3rd if statement checks if `convertToShares(totalSupply) != balanceBefore`. If the condition is met, the function will revert. Let's see if we can make `convertToShares(totalSupply) != balanceBefore`.

The `balanceBefore` is equal to `asset.balanceOf(address(this))`, which we can control by transferring the asset from our account to the vault. To see what `convertToShares(totalSupply)` is, we need to refer to ./node_modules/solmate/src/mixins/ERC4626.sol.

```solidity
function flashLoan(
    IERC3156FlashBorrower receiver,
    address _token,
    uint256 amount,
    bytes calldata data
) external returns (bool) {
    if (amount == 0) revert InvalidAmount(0); // fail early
    if (address(asset) != _token) revert UnsupportedCurrency(); // enforce ERC3156 requirement
    uint256 balanceBefore = totalAssets();
    if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // enforce ERC4626 requirement
    // [...]
}
```

#### `convertToShares(totalSupply)`

In `ERC4626.convertToShares`, we see that it returns `assets.mulDivDown(supply, totalAssets())` when `totalSupply != 0`. The `totalSupply` is indeed not `0` after the challenge is set up.

```solidity
abstract contract ERC4626 is ERC20 {
  using SafeTransferLib for ERC20;
  using FixedPointMathLib for uint256;
	// [...]
  function convertToShares(uint256 assets) public view virtual returns (uint256) {
      uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

      return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
  }
  // [...]
}
```

#### Make `convertToShares(totalSupply) != balanceBefore`

After the above analysis, we conclude that `convertToShares(totalSupply) != balanceBefore` is equivalent to $[\frac{vaultBalance \times totalSupply}{vaultBalance}] \neq vaultBalance$, where $vaultBalance$=`asset.balanceOf(address(this))`.

This can be simplified to $totalSupply \neq vaultBalance$. We can control the right-hand side of the equation, while the value on the left-hand side remains unchanged. Thus, the challenge is essentially solved.

### Solution
See [Unstoppable.t.sol](./Unstoppable.t.sol#L95).