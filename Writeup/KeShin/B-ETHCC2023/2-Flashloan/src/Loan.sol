// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IFlashLoanSimpleReceiver} from "./IFlashLoanSimpleReceiver.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {IPool} from "./IPool.sol";

contract Loan is IFlashLoanSimpleReceiver {
    IPoolAddressesProvider public constant ADDRESSES_PROVIDER = 
        IPoolAddressesProvider(0x0496275d34753A48320CA58103d5220d394FF77F);
    IPool public immutable POOL;
    address public immutable rewardToken;

    constructor(address _rewardToken) {
        rewardToken = _rewardToken;
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
    }

    mapping(address => uint256) public totalLoans;
    
    function addLoan(address token, uint256 amount) public {
        require(msg.sender == address(POOL), "!pool");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        totalLoans[msg.sender] += amount;
    }

    function addUsingFlashLoan(address token, uint256 amount) external {
        POOL.flashLoanSimple(address(this), token, amount, "", 0);
    }

    function removeLoan(address token, uint256 amount) external {
        require(totalLoans[msg.sender] > 1e23, "loan too small");
        IERC20(token).transfer(msg.sender, amount);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "!pool");
        require(amount > 1e23);
        require(IERC20(asset).balanceOf(address(this)) >= amount + amount + premium, "!amount");
        IERC20(asset).approve(address(POOL), amount + premium);
        totalLoans[initiator] += amount;
        return true;
    }
}