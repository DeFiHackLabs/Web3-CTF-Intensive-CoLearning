// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

interface IShardsNFTMarketplace {
    struct Offer {
        uint256 nftId;
        uint256 totalShards;
        uint256 stock;
        uint256 price;
        address seller;
        bool isOpen;
    }

    struct Purchase {
        uint256 shards;
        uint256 rate;
        uint64 timestamp;
        address buyer;
        bool cancelled;
    }

    event NewOffer(uint64 offerId, address indexed seller, uint256 indexed nftId, uint256 totalShards, uint256 price);
    event Fee(uint256 amount);
    event Cancelled(uint64 offerId, uint256 purchaseIndex);
    event ClosedOffer(uint64 offerId);

    error UnknownOffer();
    error UnknownNFT(uint256 nftId);
    error NotOpened(uint64 offerId);
    error OutOfStock();
    error NotAllowed();
    error BadTime();
    error AlreadyCancelled();
    error StillOpen();
    error TooManyShards();
    error MustPayFee();
    error BadRate();
    error BadAmount();
    error BadPrice();
}
