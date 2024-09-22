// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// code borrowed from repo with proxies & tests implemented in forge https://github.com/FredCoen/Proxy_implementations_with_forge

contract DasProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}