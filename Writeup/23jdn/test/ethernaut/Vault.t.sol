// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../../src/ethernaut/Vault.sol";  

contract VaultTest is Test {
    Vault public vault;
    bytes32 private password;

    function setUp() public {
        // 部署 Vault 合约并设置密码
        password = keccak256(abi.encodePacked("secret_password"));
        vault = new Vault(password);
    }

    function testUnlockVault() public {
        // 确保合约初始状态为锁定
        assertEq(vault.locked(), true);

        // 从合约的存储槽 1 中读取 password
        bytes32 storedPassword = vm.load(address(vault), bytes32(uint256(1)));

        // 打印读取到的密码，以供调试
        console.logBytes32(storedPassword);

        // 使用读取到的密码调用 unlock 函数
        vault.unlock(storedPassword);

        // 验证合约是否成功解锁
        assertEq(vault.locked(), false);
    }
}
