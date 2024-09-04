The core idea is to read the storage slot of private variables hash in the target contract.

To use foundry, we should be familiar with Test tool contract to user `vm` to get the storage content of a given slot number.

Therefore, we first deploy the target contract and note down its address. Then we peak the storage content of a given slot, thereby using our keccak method to calculate the final hash which is the same as in the target contract.