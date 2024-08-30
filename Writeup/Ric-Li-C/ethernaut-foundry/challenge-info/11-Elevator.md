# Elevator Challenge

## Ethernaut Description

This elevator won't let you reach the top of your building. Right?

### Things that might help:
- Sometimes solidity is not good at keeping promises.
- This Elevator expects to be used from a Building.

## Extra Context
The interface used doesn't require our `isLastFloor` function to be view only.
<details>
<summary>Hints</summary>
`isLastFloor` is called twice (who's to say it will return the same value twice?)
A lesson to take when creating your own contracts is that if you want use an external value twice it's better to store that value in memory instead of making two external calls where the value might change unexpectedly, it's also more gas efficient to make less external calls.
</details>