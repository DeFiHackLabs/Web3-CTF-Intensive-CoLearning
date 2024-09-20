// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/Ethernaut/good_samaritan_poc.sol";

contract GoodSamaritanPocScript is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        GoodSamaritanPoc goodSamaritanPoc = GoodSamaritanPoc(0xf384Be1106ab4Fa08cEFBcAf9F65b02FA0621dda);
        goodSamaritanPoc.exploit();

        vm.stopBroadcast();
    }
}