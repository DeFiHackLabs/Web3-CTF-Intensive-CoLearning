// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Ethernaut/hello_ethernaut.sol";

contract HelloEthernautTest is Test {
    Instance public instance;
    string constant PASSWORD = "test_password";

    function setUp() public {
        instance = new Instance(PASSWORD);
    }

    function testInfo() public view {
        assertEq(instance.info(), "You will find what you need in info1().");
    }

    function testInfo1() public view {
        assertEq(
            instance.info1(),
            'Try info2(), but with "hello" as a parameter.'
        );
    }

    function testInfo2() public view {
        assertEq(
            instance.info2("hello"),
            "The property infoNum holds the number of the next info method to call."
        );
        assertEq(instance.info2("wrong"), "Wrong parameter.");
    }

    function testInfoNum() public view {
        assertEq(instance.infoNum(), 42);
    }

    function testInfo42() public view {
        assertEq(
            instance.info42(),
            "theMethodName is the name of the next method."
        );
    }

    function testTheMethodName() public view {
        assertEq(instance.theMethodName(), "The method name is method7123949.");
    }

    function testMethod7123949() public view {
        assertEq(
            instance.method7123949(),
            "If you know the password, submit it to authenticate()."
        );
    }

    function testAuthenticate() public {
        assertEq(instance.getCleared(), false);
        instance.authenticate(PASSWORD);
        assertEq(instance.getCleared(), true);
    }

    function testAuthenticateWrongPassword() public {
        instance.authenticate("wrong_password");
        assertEq(instance.getCleared(), false);
    }
}
