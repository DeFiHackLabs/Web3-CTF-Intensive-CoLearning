// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// A new stablecoin service has emerged, and they are interested in providing support for NFT lending.
// The first NFT they have decided to support is "ETH Taipei War Room NFT".
// You can deposit your War Room NFT to get the stablecoin.
// To solve this challenge, you are required to have at least 1000 stablecoins.

import {IERC721Receiver} from "@openzeppelin-contracts-07/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin-contracts-07/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin-contracts-07/contracts/token/ERC20/ERC20.sol";
import {Base} from "../Base.sol";
import {WarRoomNFT} from "./NFT.sol";

contract Pool is ERC20("USD Taipei", "USDT"), IERC721Receiver {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(uint256 => bool)) private _userDeposits;

    address private NFTCollateral;

    constructor(address NFTCollection_) {
        NFTCollateral = NFTCollection_;
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function deposit(uint256 tokenId) external {
        IERC721(NFTCollateral).transferFrom(msg.sender, address(this), tokenId);
        _userDeposits[msg.sender][tokenId] = true;
        _balances[msg.sender] += 1 ether;
    }

    function withdraw(uint256 tokenId) external {
        require(_userDeposits[msg.sender][tokenId], "Should be owner.");
        require(_balances[msg.sender] > 0, "Should have balance.");

        IERC721(NFTCollateral).safeTransferFrom(address(this), msg.sender, tokenId);
        _balances[msg.sender] -= 1 ether;
        delete _userDeposits[msg.sender][tokenId];
    }

    function isSolved(address user) external view returns (bool) {
        return _balances[user] > 1000 ether;
    }
}

contract PoolBase is Base {
    WarRoomNFT public nft;
    Pool public pool;
    uint256 public tokenId;
    address public challenger;

    constructor(uint256 startTime, uint256 endTime, uint256 fullScore) Base(startTime, endTime, fullScore) {}

    function setup() external override {
        challenger = msg.sender;
        nft = new WarRoomNFT();
        pool = new Pool(address(nft));
        tokenId = nft.mint(challenger);
    }

    function solve() public override {
        require(pool.isSolved(challenger));
        super.solve();
    }
}
