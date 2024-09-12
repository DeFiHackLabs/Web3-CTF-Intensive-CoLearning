// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract FreeRiderRecoveryManager is ReentrancyGuard, IERC721Receiver {
    using Address for address payable;

    uint256 private immutable bounty;
    address private immutable beneficiary;
    IERC721 private immutable nft;
    uint256 private received;

    error NotEnoughFunds();
    error CallerNotNFT();
    error OriginNotBeneficiary();
    error InvalidTokenID(uint256 tokenId);
    error StillNotOwningToken(uint256 tokenId);

    constructor(address _beneficiary, address _nft, address owner, uint256 _bounty) payable {
        if (msg.value != _bounty) {
            revert NotEnoughFunds();
        }
        bounty = _bounty;
        beneficiary = _beneficiary;
        nft = IERC721(_nft);
        IERC721(_nft).setApprovalForAll(owner, true);
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external
        override
        nonReentrant
        returns (bytes4)
    {
        if (msg.sender != address(nft)) {
            revert CallerNotNFT();
        }

        if (tx.origin != beneficiary) {
            revert OriginNotBeneficiary();
        }

        if (_tokenId > 5) {
            revert InvalidTokenID(_tokenId);
        }

        if (nft.ownerOf(_tokenId) != address(this)) {
            revert StillNotOwningToken(_tokenId);
        }

        if (++received == 6) {
            address recipient = abi.decode(_data, (address));
            payable(recipient).sendValue(bounty);
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
