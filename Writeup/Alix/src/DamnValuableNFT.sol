// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";

/**
 * @notice Mintable and burnable NFT with role-based access controls.
 */
contract DamnValuableNFT is ERC721, ERC721Burnable, OwnableRoles {
    uint256 public constant MINTER_ROLE = _ROLE_0;
    uint256 public nonce;

    constructor() ERC721("DamnValuableNFT", "DVNFT") {
        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, MINTER_ROLE);
    }

    function safeMint(address to) public onlyRoles(MINTER_ROLE) returns (uint256 tokenId) {
        tokenId = nonce;
        _safeMint(to, tokenId);
        ++nonce;
    }
}
