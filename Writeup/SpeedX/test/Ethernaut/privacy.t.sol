// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "Ethernaut/privacy_poc.sol";

contract PrivacyTest is Test {
    Privacy privacy;
    PrivacyPoc privacyPoc;

    function setUp() public {
        bytes32[3] memory data = [
          bytes32(0xb98504952af1f99020fb0dc6521bbf29888030d3680560c8d6fe7169eadc7896),
          bytes32(0x8d5f751e62a510ba3d365eb47ab921a2ee36daf195f2d2081222c3aecefa3f66),
          bytes32(0x8de7238b78942005fea750232d184d0ce84a53d569bd7c825b99b79d02c50d1c)
        ];

        privacy = new Privacy(data);  
        privacyPoc = new PrivacyPoc(address(privacy));
    }

    function testExploit() public {
        assertTrue(privacy.locked());
        privacyPoc.exploit();
        assertTrue(!privacy.locked());
    }
}