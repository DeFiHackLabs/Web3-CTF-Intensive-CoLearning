// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Stake} from "../src/Stake.sol";

contract StakeTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6733964);
    }

    function test_Stake() public {
        Stake stake = Stake(0x8F9457389FD5f54CDAeb59FA053261A3428F698B);

        console.log("totalStaked : ", stake.totalStaked()); // 0

        console.log("ca eth balance : ", payable(address(stake)).balance); // 0

        address weth = 0xCd8AF4A0F29cF7966C051542905F66F5dca9052f;

        address userA = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;
        address userB = 0x9b20948606A59671C2019Bad4085AA0f8bC7860F;

        vm.startPrank(userA);
        
        payable(userB).transfer(0.1 ether);

        stake.StakeETH{value : 0.01 ether}();

        stake.Unstake(0.01 ether);

        vm.stopPrank();

        vm.startPrank(userB);

        stake.StakeETH{value : 0.01 ether}();

        (bool success, bytes memory data) = weth.call{value: 0.01 ether}(abi.encodeWithSignature("deposit()", ""));

        (bool success1, bytes memory data1) = weth.call(abi.encodeWithSignature("approve(address, uint256)", address(stake), uint256(0.5 ether)));

        (bool success2, bytes memory data2) = weth.call(abi.encodeWithSignature("balanceOf(address)", userB));

        console.log("userB weth balance : ", bytesToUint(data2));

        stake.StakeWETH(0.01 ether);

        console.log("totalStaked : ", stake.totalStaked()); 

        console.log("ca eth balance : ", payable(address(stake)).balance);

        console.log("user is staker : ", stake.Stakers(userA));

        console.log("user stake balance : ", stake.UserStake(userA));
    }
}
