// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/18-MagicNumber/MagicNumber.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract SendTransaction {
    constructor () {
        assembly {
            mstore(0, 0x602A60805260206080F3)
            return(0x16, 0x0a)
        }
    }
}


contract Level18Solution is Script {
    MagicNum _magicNumberInstance = MagicNum(0x9771216E425e48D72993b0CC2bd40BAA7b72c319);

    function run() public{
        vm.startBroadcast();
        SendTransaction _sendTransactionInstance = new SendTransaction();
        console.log("Created Address : ", address(_sendTransactionInstance));
        _magicNumberInstance.setSolver(address(_sendTransactionInstance));
        vm.stopBroadcast();
    }
}