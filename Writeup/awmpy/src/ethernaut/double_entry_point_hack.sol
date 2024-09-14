// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDoubleEntryPoint {
    function forta() external returns (Forta);
    function cryptoVault() external returns (address);
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

contract DoubleEntryPointHack is IDetectionBot {
    address public cryptoVault;

    constructor(address _cryptoVault) {
        cryptoVault = _cryptoVault;
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        // 通过直接阻止调用 delegateTransfer函数也可过关
        //if (keccak256(abi.encodeWithSignature("delegateTransfer(address,uint256,address)")) == keccak256(msgData[:4])) {
        //    IForta(msg.sender).raiseAlert(user);
        //}
        address origSender;
        assembly {
            origSender := calldataload(0xa8)
        }
        if(origSender == cryptoVault) {
            IForta(msg.sender).raiseAlert(user);
        }
    }
}
