The core idea is to bypass the `isContract()` check so as to become the owner of the target `RoadClosed` contract.

The operation can be divided into 3 steps in the contract's constructor:
- `addToWhitelist(address(attacker))`
- `changeOwner(address(attacker))`
- `pwn(address(attacker))`

The identification of whether an address is a contract or not should not just rely on the exitcodesize, which can be manipulated to bypass.