# Reentrance Challenge

## Ethernaut Description

The goal of this level is for you to steal all the funds from the contract.

### Things that might help:

- Untrusted contracts can execute code where you least expect it.
- Fallback methods
- Throw/revert bubbling
- Sometimes the best way to attack a contract is with another contract.

## Extra Context
- What happens when a contract tries to send ether to another contract via call?
- [Solidity by Example Reentrancy](https://solidity-by-example.org/hacks/re-entrancy/)
- The lesson to learn here is to always try to adhere to the [CEI(checks, effects, interactions)](https://docs.soliditylang.org/en/v0.6.11/security-considerations.html) pattern wherever possible and/or add a [ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol) to functions that make external calls.