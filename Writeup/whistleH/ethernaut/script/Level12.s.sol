// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/12-Privacy/Privacy.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Level12Solution is Script {
    Privacy privacyInstance = Privacy(0xBa0A4a42D133c0Bb014C4900ED29D8EB7b47B3df);

    function run() public{
        vm.startBroadcast();
        bytes32 lockData = 0x65030b90e31b07fdf0c43887c63cfe304abd1b35cfa20666282b66f839937a23;
        privacyInstance.unlock(bytes16(lockData));
        console.log("locked : ", privacyInstance.locked());
        vm.stopBroadcast();
    }
}