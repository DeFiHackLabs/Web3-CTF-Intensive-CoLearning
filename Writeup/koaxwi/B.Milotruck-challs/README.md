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

## Escrow (2024/09/15)

In this challenge, we need to drain an `Escrow`.

The `Escrow` has three non-view functions: `initialize` can only be used once, while `deposit` and `withdraw` are only for the owner.
The contract does not use `Ownable` or store the owner address, instead it queries its factory with its id (hash), and the factory records the owners using NFT.
Since the setup has renounced ownership of the `Escrow`, if we can deploy a new escrow with the same hash, we become the owner of both escrows.

The deployment of escrows is interesting.
The factory is using a library `ClonesWithImmutableArgs` (CWIA) to deploy (actually clone) the contract.
When calling functions of the deployed(cloned) contracts, it will internally append the "immutable args" to the calldata, and another `uint16` representing the arg length, then triggers a self-delegated call with the new calldata.
Then the contract can read the "immutable args" via `_getArgAddress`.

We cannot add other escrow implementations to directly return the hash, which is calculated using an identifier, the factory address and two token addresses.
So we have to deploy our escrow with same parameters.
However the factory rejects the copy-pasting of the deployment codes as it has already be deployed.

The immutable args (the two token addresses, and the second is `address(0)`) are provide in a combined `bytes`.
By appending other garbage chars, we can bypass the deployed check, but `initialize` will fail due to the overlong calldata.
If we directly drop the second zero address, the CWIA length will be read as non-zero address.
Since the length is less than 256, we can just drop a single null byte, and let the higher byte of CWIA length to fill it.

## Simple AMM Vault (TODO)

## Voting Vault (TODO)

## Meta Staking (TODO)

## Gnosis Unsafe (TODO)

