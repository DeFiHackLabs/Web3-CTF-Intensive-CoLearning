// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import {Script, console2} from "forge-std/Script.sol";

interface IDoubleEntryPoint {
    function forta() external returns (Forta);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

contract Forta is IForta {
  mapping(address => IDetectionBot) public usersDetectionBots;
  mapping(address => uint256) public botRaisedAlerts;

  function setDetectionBot(address detectionBotAddress) external override {
      usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
  }

  function notify(address user, bytes calldata msgData) external override {
    if(address(usersDetectionBots[user]) == address(0)) return;
    try usersDetectionBots[user].handleTransaction(user, msgData) {
        return;
    } catch {}
  }

  function raiseAlert(address user) external override {
      if(address(usersDetectionBots[user]) != msg.sender) return;
      botRaisedAlerts[msg.sender] += 1;
  } 
}

contract DoubleEntryPointAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        if (keccak256(abi.encodeWithSignature("delegateTransfer(address,uint256,address)")) == keccak256(msgData[:4])) {
            IForta(msg.sender).raiseAlert(user);
        }
    }
}