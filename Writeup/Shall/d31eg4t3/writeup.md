The core idea is to make the delegatecall change the slot 5 of the target contract to the attacker contract.

It is noticeable that this operation can be implemented in the fallback() function of the attacker contract as if the calldata does not meet any of the funciton, the fallback can be invoked.

Therefore, we can first craft a storage slot at index 5 and change it to the `address(this)`, the attacker contract to successfully make the target contract change its owner to the attacker contract.