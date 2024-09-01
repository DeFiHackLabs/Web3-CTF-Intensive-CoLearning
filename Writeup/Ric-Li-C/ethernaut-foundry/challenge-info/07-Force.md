# Force Challenge

## Ethernaut Description

Some contracts will simply not take your money ¯\_(ツ)_/¯

The goal of this level is to make the balance of the contract greater than zero.

Things that might help:
- Fallback methods
- Sometimes the best way to attack a contract is with another contract.

## Extra Hints
<details>
<summary>Hints</summary>
Even if a contract has no fallback/receive functions it's susceptible to receiving ether via another contract using the selfdestruct opcode.

See: [Solidity by Example Self Destruct](https://solidity-by-example.org/hacks/self-destruct/)

This highlights the importance of never assuming your contract's ether balance will be zero as it can lead to errors where you contracts internal accounting logic doesn't match the contract's actual balance.
</details>