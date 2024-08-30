# Delegation Challenge

## Ethernaut Description

The goal of this level is for you to claim ownership of the instance you are given.

Things that might help
- Look into Solidity's documentation on the delegatecall low level function, how it works, how it can be used to delegate operations to on-chain libraries, and what implications it has on execution scope.
- Fallback methods
- Method ids

## Extra Context
- It's important to get a good understanding of delegatecall & how it differs to a regular call, as it's used often in modern upgradeable/proxy contracts and there are a bunch of common pitfalls that come with it.
See: [Solidity by Example delegatecall](https://solidity-by-example.org/delegatecall/)
