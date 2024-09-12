// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {DamnValuableToken, ERC20} from "./DamnValuableToken.sol";

/**
 * @notice Stake your Damn Valuable Tokens, to earn more Damn Valuable Tokens.
 */
contract DamnValuableStaking is ERC20 {
    DamnValuableToken public immutable token;
    uint256 public immutable rate; // tokens per second

    uint256 public lastUpdate;
    mapping(address staker => uint256) public stakerRewardPerToken;
    mapping(address => uint256) public rewards;

    uint256 private _rewardPerToken;

    error InvalidAmount();
    error InvalidRate();

    event RewardUpdated(address staker, uint256 rewards, uint256 rewardPerToken);

    constructor(DamnValuableToken _dvt, uint256 _rate) ERC20("Damn Valuable Staked Token", "stDVT", 18) {
        if (_rate == 0) revert InvalidRate();
        token = _dvt;
        rate = _rate;
        lastUpdate = block.timestamp;
    }

    function _updateReward(address staker) private {
        _rewardPerToken = rewardsPerToken();
        lastUpdate = block.timestamp;
        if (staker != address(0)) {
            rewards[staker] = earned(staker);
            stakerRewardPerToken[staker] = _rewardPerToken;
        }
        emit RewardUpdated(staker, rewards[staker], stakerRewardPerToken[staker]);
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();

        _updateReward(msg.sender);
        _mint(msg.sender, amount);

        token.transferFrom(msg.sender, address(this), amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _updateReward(msg.sender);
        _updateReward(recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _updateReward(msg.sender);
        _updateReward(recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        if (amount == 0) revert InvalidAmount();

        _updateReward(msg.sender);
        _burn(msg.sender, amount);

        token.transfer(msg.sender, amount);
        return amount;
    }

    function claim() external returns (uint256) {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            delete rewards[msg.sender];
            token.transfer(msg.sender, reward);
        }
        return reward;
    }

    function rewardsPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return _rewardPerToken;
        } else {
            return _rewardPerToken + ((block.timestamp - lastUpdate) * rate * 1e18) / totalSupply;
        }
    }

    function earned(address staker) public view returns (uint256) {
        return balanceOf[staker] * (rewardsPerToken() - stakerRewardPerToken[staker]) / 1e18 + rewards[staker];
    }
}
