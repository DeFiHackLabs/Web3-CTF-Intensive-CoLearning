## [Free Rider](https://www.damnvulnerabledefi.xyz/challenges/free-rider/)

> A new marketplace of Damn Valuable NFTs has been released! There’s been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.
>
> A critical vulnerability has been reported, claiming that all tokens can be taken. Yet the developers don’t know how to save them!
>
> They’re offering a bounty of 45 ETH for whoever is willing to take the NFTs out and send them their way. The recovery process is managed by a dedicated smart contract.
>
> You’ve agreed to help. Although, you only have 0.1 ETH in balance. The devs just won’t reply to your messages asking for more.
>
> If only you could get free ETH, at least for an instant.

```solidity
function _isSolved() private {
  // The recovery owner extracts all NFTs from its associated contract
  for (uint256 tokenId = 0; tokenId < AMOUNT_OF_NFTS; tokenId++) {
    vm.prank(recoveryManagerOwner);
    nft.transferFrom(address(recoveryManager), recoveryManagerOwner, tokenId);
    assertEq(nft.ownerOf(tokenId), recoveryManagerOwner);
  }

  // Exchange must have lost NFTs and ETH
  assertEq(marketplace.offersCount(), 0);
  assertLt(address(marketplace).balance, MARKETPLACE_INITIAL_ETH_BALANCE);

  // Player must have earned all ETH
  assertGt(player.balance, BOUNTY);
  assertEq(address(recoveryManager).balance, 0);
}
```

### Analysis

First, the `FreeRiderNFTMarketplace.buyMany` function does not check if the `msg.value` is greater than or equal to the TOTAL price of the NFTs. Therefore, we can pay for one and buy all of them! Second, the code `payable(_token.ownerOf(tokenId)).sendValue(priceToPay)` does not pay the original owner; it pays the buyer. The final problem we need to solve is that we do not have enough balance.

```solidity
// marketplace = new FreeRiderNFTMarketplace{value: MARKETPLACE_INITIAL_ETH_BALANCE}(AMOUNT_OF_NFTS);
contract FreeRiderNFTMarketplace is ReentrancyGuard {
    // [...]
    function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            unchecked {
                _buyOne(tokenIds[i]);
            }
        }
    }

    function _buyOne(uint256 tokenId) private {
        uint256 priceToPay = offers[tokenId];
        if (priceToPay == 0) {
            revert TokenNotOffered(tokenId);
        }

        if (msg.value < priceToPay) {
            revert InsufficientPayment();
        }

        --offersCount;

        // transfer from seller to buyer
        DamnValuableNFT _token = token; // cache for gas savings
        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        // pay seller using cached token
        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

        emit NFTBought(msg.sender, tokenId, priceToPay);
    }

    receive() external payable {}
}
```

#### Get Enough Balance Using Flash Swap

Fortunately, the challenge provides us with `UniswapV2`! We can use a flash swap (which is similar to a flash loan) to borrow a sufficient amount of WETH, solve the challenge, and repay the amount borrowed plus a fee.

### Solution
See [FreeRider.t.sol](./FreeRider.t.sol#L127).