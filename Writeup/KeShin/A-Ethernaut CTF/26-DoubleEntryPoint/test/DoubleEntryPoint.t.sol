// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DoubleEntryPoint, IDetectionBot, IForta, Forta, LegacyToken, CryptoVault} from "../src/DoubleEntryPoint.sol";

contract DoubleEntryPointTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6701005);
    }

    function test_Bot() public {
        address user = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;
        vm.startPrank(user);

        DoubleEntryPoint doubleEntryPoint = DoubleEntryPoint(0x8b3aD35dd009FB4a298F5cce7977f58c0F506711);
        
        Forta forta = doubleEntryPoint.forta();
        
        CryptoVault cryptoVault = CryptoVault(doubleEntryPoint.cryptoVault());

        console.log("cryptoVault sweptTokensRecipient : ", cryptoVault.sweptTokensRecipient());
        console.log("cryptoVault underlying : ", address(cryptoVault.underlying()));
        
        LegacyToken legacyToken = LegacyToken(doubleEntryPoint.delegatedFrom());

        console.log("legacyToken 's delegate : ", address(legacyToken.delegate()));

        DetectionBot detectionBot = new DetectionBot();

        forta.setDetectionBot(address(detectionBot));

        // should revert
        cryptoVault.sweepToken(cryptoVault.underlying());
    }

}

contract DetectionBot is IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external {
        Forta forta = Forta(0xbC0dc30bB22fA395C2391bA9aa43399855Fa281C);

        forta.raiseAlert(user);
    }
}