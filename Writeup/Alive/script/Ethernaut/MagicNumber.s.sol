// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {Helper} from "../../test/Ethernaut/MagicNumber.t.sol";
import {MagicNum} from "../../src/Ethernaut/MagicNumber.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        MagicNum magicNum = MagicNum(
            0x5AcDe5D61213eeaaf174EbF837b402B7C2AAf66D
        );
        Helper helper = new Helper();
        magicNum.setSolver(address(helper));
        vm.stopBroadcast();
    }
}
