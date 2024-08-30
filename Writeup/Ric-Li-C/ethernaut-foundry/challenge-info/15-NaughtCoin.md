# NaughtCoin Challenge

## Ethernaut Description

NaughtCoin is an ERC20 token and you're already holding all of them. The catch is that you'll only be able to transfer them after a 10 year lockout period. Can you figure out how to get them out to another address so that you can transfer them freely? Complete this level by getting your token balance to 0.

**Things that might help**

- The ERC20 Spec
- The OpenZeppelin codebase

## Extra Context

Vesting of ERC20 tokens is common. However this is a very rudimentary approach to it.
NaughtCoin inherits OpenZeppelins ERC20 contract and overrides the transfer function, but are there other functions you could use? 
