// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface Instance {
    function info() external returns (string memory);

    function info1() external returns (string memory);

    function info2(string memory param) external returns (string memory);

    function infoNum() external returns (uint8);

    function info42() external returns (string memory);

    function theMethodName() external returns (string memory);

    function method7123949() external returns (string memory);

    function authenticate(string memory passkey) external;

    function password() external view returns (string memory);

    function getCleared() external view returns (bool);
}

contract Level0 is Test {
    function setUp() public {}

    function testExploit() public {
        Instance level0 = Instance(0xEF23FE7b3409F33C7DC02feEfa7D347Cf304932A);
        console.log(level0.info()); // "You will find what you need in info1()."
        console.log(level0.info1()); // "Try info2(), but with \"hello\" as a parameter."
        console.log(level0.info2("hello")); // "The property infoNum holds the number of the next info method to call."
        console.log(level0.infoNum()); // 42
        console.log(level0.info42()); // "theMethodName is the name of the next method."
        console.log(level0.theMethodName()); // "The method name is method7123949."
        console.log(level0.method7123949()); // "If you know the password, submit it to authenticate()."
        console.log(level0.password());

        level0.authenticate(level0.password());

        console.log(level0.getCleared());
    }
}
