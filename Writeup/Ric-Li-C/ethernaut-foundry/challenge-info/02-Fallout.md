# Fallout Challenge

## Ethernaut Description
Claim ownership of the contract below to complete this level.

Things that might help:
- Solidity Remix IDE

## Extra Context
Prior to Solidity version 0.4.22 the method for creating a constructor was to have a function with the same name as the contract. This caused issues because if the contract name changed but the function name stayed the same, it was no longer treated as a constructor can could be called like any other function.
