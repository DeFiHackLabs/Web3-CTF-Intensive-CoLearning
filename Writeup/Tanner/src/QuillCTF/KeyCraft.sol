// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract KeyCraft is ERC721 {
    uint256 totalSupply;
    address owner;
    bool buyNFT;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _mint(msg.sender, totalSupply++);
        owner = msg.sender;
    }

    modifier checkAddress(bytes memory b) {
        bool q;
        bool w;

        if (msg.sender == owner) {
            buyNFT = true;
        } else {
            uint256 a = uint160(uint256(keccak256(b)));
            q = (address(uint160(a)) == msg.sender);

            a = a >> 108;
            a = a << 240;
            a = a >> 240;

            w = (a == 13057);
        }

        buyNFT = (q && w) || buyNFT;
        _;
        buyNFT = false;
    }

    function mint(bytes memory b) public payable checkAddress(b) {
        require(msg.value >= 1 ether || buyNFT, "Not allowed to mint.");
        _mint(msg.sender, totalSupply++);
    }

    function burn(uint256 tok) public {
        address a = ownerOf(tok);
        require(msg.sender == a);
        _burn(tok);
        totalSupply--;
        payable(a).transfer(1 ether);
    }
}
