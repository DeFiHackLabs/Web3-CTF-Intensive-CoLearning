# GatekeeperOne Challenge

## Ethernaut Description

Make it past the gatekeeper and register as an entrant to pass this level.

### Things that might help:
- Remember what you've learned from the Telephone and Token levels.
- You can learn more about the special function gasleft().

## Extra Context
- This is 3 challenges in one.
- Remember you can specify `{gas : XXX}` when making a call in the same way as `{value: XXX}`
- Get a good understanding of solidity's type casting

### Things to make sure you understand
What's the difference between bytes8 & uint64 in the EVM?
What happens when you cast a uint64 down to a uint32?
What's happening with uint16(uint160(tx.origin))?