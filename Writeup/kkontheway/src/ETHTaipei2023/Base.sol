// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

abstract contract Base {
    uint256 private immutable _startTime;
    uint256 private immutable _endTime;
    uint256 private immutable _fullScore;

    uint256 private _completeTime;

    constructor(uint256 startTime, uint256 endTime, uint256 fullScore) {
        require(startTime >= block.timestamp, "wrong start time");
        require(endTime >= startTime, "wrong end time");
        _startTime = startTime;
        _endTime = endTime;
        _fullScore = fullScore;
    }

    function setup() external virtual;

    function getCurrentScore() external view returns (uint256) {
        return _getScore(block.timestamp);
    }

    function getFinalScore() external view returns (uint256) {
        if (isSolved()) {
            return _getScore(_completeTime);
        } else {
            return 0;
        }
    }

    function solve() public virtual {
        _completeTime = block.timestamp;
    }

    function isSolved() public view returns (bool) {
        return _completeTime != 0;
    }

    function _getScore(uint256 timestamp) internal view returns (uint256) {
        if (timestamp < _startTime) {
            return _fullScore;
        } else if (timestamp > _endTime) {
            return 0;
        } else {
            uint256 dScore = timestamp - _startTime;
            if (dScore > _fullScore) {
                return 0;
            } else {
                return _fullScore - dScore;
            }
        }
    }
}
