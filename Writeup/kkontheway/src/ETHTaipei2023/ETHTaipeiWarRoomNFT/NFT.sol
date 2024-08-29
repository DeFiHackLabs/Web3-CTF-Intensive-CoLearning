// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {ERC721} from "@openzeppelin-contracts-07/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin-contracts-07/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin-contracts-07/contracts/utils/Address.sol";

contract WarRoomNFT is ERC721("ETHTaipeiWarRoom", "war-room-nft"), Ownable {
    using Address for address;

    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = totalSupply() + 1;
        _mint(to, tokenId);
    }
}
