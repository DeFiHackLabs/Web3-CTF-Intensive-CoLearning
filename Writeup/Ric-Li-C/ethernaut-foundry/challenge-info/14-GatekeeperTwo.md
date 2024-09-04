# GatekeeperTwo Challenge

## Ethernaut Description

This gatekeeper introduces a few new challenges. Register as an entrant to pass this level.

### Things that might help:
- Remember what you've learned from getting past the first gatekeeper - the first gate is the same.
- The assembly keyword in the second gate allows a contract to access functionality that is not native to vanilla Solidity. See [here](https://docs.soliditylang.org/en/v0.4.23/assembly.html) for more information. The extcodesize call in this gate will get the size of a contract's code at a given address - you can learn more about how and when this is set in section 7 of [the yellow paper](https://ethereum.github.io/yellowpaper/paper.pdf).
- The ^ character in the third gate is a bitwise operation (XOR), and is used here to apply another common bitwise operation. The Coin Flip level is also a good place to start when approaching this challenge.

## Extra Context
- [EVM.codes](https://www.evm.codes/) the go to cheatsheet for an overview of EVM opcodes, the items they take from the stack and what they return. This can be helpful to work out whats going on in assembly blocks.
- Bitwise operations, these come up quite a lot in both CTFs & in the wild when trying to pack data to save gas, getting a good understanding of them is important.