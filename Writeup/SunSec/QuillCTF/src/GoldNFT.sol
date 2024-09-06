// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

interface IPassManager {
    function read(bytes32) external returns (bool);
}

contract GoldNFT is ERC721("GoldNFT", "GoldNFT") {
    uint lastTokenId;
    bool minted;

    function takeONEnft(bytes32 password) external {
        require(
            IPassManager(0xe43029d90B47Dd47611BAd91f24F87Bc9a03AEC2).read(
                password
            ),
            "wrong pass"
        );

        if (!minted) {
            lastTokenId++;
            _safeMint(msg.sender, lastTokenId);
            minted = true;
        } else revert("already minted");
    }
}
