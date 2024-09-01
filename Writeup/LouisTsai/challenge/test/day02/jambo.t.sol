// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Challenge} from "../../src/day02/jambo.sol";

interface Jambo {
    function answer(bytes memory _answer) external payable;
    function start(uint256 qid, bytes32 _answer) external payable;
    function revokeOwnership() external;
}

contract JamboTest is Test {
    Challenge challenge;
    address internal user;

    function setUp() public {
        deal(user, 3 ether);
        user = makeAddr("user");
        challenge = new Challenge{value: 25 ether}();
    }

    function testExploit() public {
        vm.startPrank(user);
        bytes memory data = hex"66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64";
        console2.log(user.balance);
        Jambo(address(challenge.target())).answer{value: 1 ether + 1 wei}(data);
        // console2.log(challenge.isSolved());
        vm.stopPrank();
    }
}
