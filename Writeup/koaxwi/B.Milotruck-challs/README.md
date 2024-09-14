# Milotruck Challenges Writeup

Challenges: https://github.com/MiloTruck/evm-ctf-challenges

For this set of challenges, each task has a `Setup.sol` to setup the environment (while DVD is doing this in each test's `setUp` function), to provide the player an onetime airdrop and to check the challenge solving status.

The author has already provided the solution in the `test` folder.
Since the test scripts have nothing to do with setting up and solution checks, I removed them and planned to write my own from scratch.

## GreyHats Dollar (2024/09/14)

This challenge defines a token(-like) contract with deflation.
There is shares, convertion rate, deflation rate.... All of them are not important (not related to the bug).

The contract allows transfering tokens to self.
This typically does not cause problems, however, when updating the balances(shares), the contract is not using inplace add/sub (i.e. `+=` or `-=`)
Instead, it first calculates the two new values, then sets them.
When transferring to self, the balances will be updated twice, and the second will overwrite the first.
In this case, it is the receiver's balance overwriting the payer's balance.
So, tokens emerged from nowhere will be added to our balance.

## Escrow (TODO)

## Simple AMM Vault (TODO)

## Voting Vault (TODO)

## Meta Staking (TODO)

## Gnosis Unsafe (TODO)

