// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract InvestPool {
    IERC20 token;
    uint256 totalShares;
    bool initialized;
    mapping(address => uint256) public balance;

    modifier onlyInitializing() {
        require(initialized, "Not initialized! You are so stupid!");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    function initialize(string memory password) external {
        // Password could be found in Goerli contract
        // 0xA45aC53E355161f33fB00d3c9485C77be3c808ae
        // Hint: Password length is more than 30 chars
        require(!initialized, "Already initialized");
        require(
            keccak256(abi.encode(password)) == 0x18617c163efe81229b8520efdba6384eb5c6d504047da674138c760e54c4e1fd,
            "Wrong password"
        );
        initialized = true;
    }

    function deposit(uint256 amount) external onlyInitializing {
        uint256 userShares = tokenToShares(amount);
        balance[msg.sender] += userShares;
        totalShares += userShares;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function tokenToShares(uint256 userAmount) public view returns (uint256) {
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance == 0) return userAmount;
        return (userAmount * totalShares) / tokenBalance;
    }

    function sharesToToken(uint256 amount) public view returns (uint256) {
        uint256 tokenBalance = token.balanceOf(address(this));
        return (amount * tokenBalance) / totalShares;
    }

    function transferFromShare(uint256 amount, address from) public {
        uint256 size;
        assembly {
            size := extcodesize(address())
        }
        require(size == 0, "code size is not 0");
        require(balance[from] >= amount, "amount is too big");
        balance[from] -= amount;
        balance[msg.sender] += amount;
    }

    function withdrawAll() external onlyInitializing {
        uint256 shares = balance[msg.sender];
        uint256 toWithdraw = sharesToToken(shares);
        balance[msg.sender] = 0;
        totalShares -= shares;
        token.transfer(msg.sender, toWithdraw);
    }
}
