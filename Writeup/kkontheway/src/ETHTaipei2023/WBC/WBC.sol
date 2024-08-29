// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Players are welcome to join this famous world baseball championship.
// To win the championship, players need to solve the challenges to score.
// Let's see who will be the MVP this year!

import {Base} from "../Base.sol";

interface IGame {
    function judge() external view returns (address);
    function steal() external view returns (uint256);
    function execute() external returns (bytes32);
    function shout() external view returns (bytes memory);
}

contract WBC {
    address private immutable judge;
    address internal player;
    bool public scored;

    constructor() {
        judge = block.coinbase;
    }

    modifier onlyPlayer() {
        require(msg.sender == player, "security!");
        _;
    }

    function bodyCheck() external {
        require(msg.sender.code.length == 0, "no personal stuff");
        require(uint256(uint160(msg.sender)) % 100 == 10, "only valid players");

        player = msg.sender;
    }

    function ready() external {
        require(IGame(msg.sender).judge() == judge, "wrong game");
        _swing();
    }

    function homerun() external {
        require(block.timestamp % 23_03_2023 == 0, "try again");
        scored = true;
    }

    function decode(bytes32 data) external pure returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x49, data)
            return(0x20, 0x60)
        }
    }

    function _swing() internal onlyPlayer {
        _firstBase();
        require(scored, "failed");
    }

    function _firstBase() internal {
        uint256 o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o = 1001000030000000900000604030700200019005002000906;
        uint256 o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o = 460501607330902018203080802016083000650930542070;
        uint256 o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o = 256; // 2^8
        uint256 o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o = 1;
        _secondBase(
            uint160(
                o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o
                    + o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o * o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o
                    - o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o
            )
        );
    }

    function _secondBase(uint160 input) internal {
        require(IGame(msg.sender).steal() == input, "out");
        _thirdBase();
    }

    function _thirdBase() internal {
        require(keccak256(abi.encodePacked(this.decode(IGame(msg.sender).execute()))) == keccak256("HitAndRun"), "out");
        _homeBase();
    }

    function _homeBase() internal {
        scored = true;

        (bool succ, bytes memory data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
        require(succ, "out");
        require(
            keccak256(abi.encodePacked(abi.decode(data, (string)))) == keccak256(abi.encodePacked("I'm the best")),
            "out"
        );

        (succ, data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
        require(succ, "out");
        require(
            keccak256(abi.encodePacked(abi.decode(data, (string))))
                == keccak256(abi.encodePacked("We are the champion!")),
            "out"
        );
    }
}

contract WBCBase is Base {
    WBC public wbc;

    constructor(uint256 startTime, uint256 endTime, uint256 fullScore) Base(startTime, endTime, fullScore) {}

    function setup() external override {
        wbc = new WBC();
    }

    function solve() public override {
        require(wbc.scored());
        super.solve();
    }
}
