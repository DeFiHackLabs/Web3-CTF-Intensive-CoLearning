---
timezone: Pacific/Auckland
---

> 请在上边的 timezone 添加你的当地时区，这会有助于你的打卡状态的自动化更新，如果没有添加，默认为北京时间 UTC+8 时区
> 时区请参考以下列表，请移除 # 以后的内容

timezone: Pacific/Honolulu # 夏威夷-阿留申标准时间 (UTC-10)

timezone: America/Anchorage # 阿拉斯加标准时间 (UTC-9)

timezone: America/Los_Angeles # 太平洋标准时间 (UTC-8)

timezone: America/Denver # 山地标准时间 (UTC-7)

timezone: America/Chicago # 中部标准时间 (UTC-6)

timezone: America/New_York # 东部标准时间 (UTC-5)

timezone: America/Halifax # 大西洋标准时间 (UTC-4)

timezone: America/St_Johns # 纽芬兰标准时间 (UTC-3:30)

timezone: America/Sao_Paulo # 巴西利亚时间 (UTC-3)

timezone: Atlantic/Azores # 亚速尔群岛时间 (UTC-1)

timezone: Europe/London # 格林威治标准时间 (UTC+0)

timezone: Europe/Berlin # 中欧标准时间 (UTC+1)

timezone: Europe/Helsinki # 东欧标准时间 (UTC+2)

timezone: Europe/Moscow # 莫斯科标准时间 (UTC+3)

timezone: Asia/Dubai # 海湾标准时间 (UTC+4)

timezone: Asia/Kolkata # 印度标准时间 (UTC+5:30)

timezone: Asia/Dhaka # 孟加拉国标准时间 (UTC+6)

timezone: Asia/Bangkok # 中南半岛时间 (UTC+7)

timezone: Asia/Shanghai # 中国标准时间 (UTC+8)

timezone: Asia/Taipei # 台灣标准时间 (UTC+8)

timezone: Asia/Tokyo # 日本标准时间 (UTC+9)

timezone: Australia/Sydney # 澳大利亚东部标准时间 (UTC+10)

timezone: Pacific/Auckland # 新西兰标准时间 (UTC+12)

---

# doublespending

1. 自我介绍 Doublespending
2. 你认为你会完成本次残酷学习吗？Yes

## Notes

<!-- Content_START -->

### 2024.08.29

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- UnstoppableVault
  - `UnstoppableMonitor.onFlashLoan` revert when [`convertToShares(totalSupply) != balanceBefore`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableVault.sol#L85C13-L85C58)
  - We can get the share amount by `convertToShares(totalSupply)`
  - In normal case, share amount equals to asset amount by `deposit` or `mint` method.
  - However, if we transfer the token to the pool directly, the share amount does not changed but the asset amount increases.
- NaiveReceiver
  - We can send all weth of `IERC3156FlashBorrower receiver` to `feeReceiver` by calling [flashLoan](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L43C24-L43C54) 10 times
  - Then, we use `Forwrarder` to call `Multicall` with a `withdraw` call.
  - [In this case, `msg.sender` is `Forwarder` and the pool will use the last 20 bytes as the `sender`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L87)
  - So, we can append `feeReceiver` to the `withdraw` call to act as `feeReceiver`.

### 2024.08.30

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Truster
  - [`target.functionCall(data)`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/truster/TrusterLenderPool.sol#L28) can be a `token.approve(player, TOKENS_IN_POOL)` call.
  - To by pass [the balance check](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/truster/TrusterLenderPool.sol#L30), we can set `amount` of `flashLoad` to be 0
  - Finally, palyer can use `token.transferFrom` to rescue all funds in the pool.
- Side Entrance
  - To by pass [the balance check](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/side-entrance/SideEntranceLenderPool.sol#L40-L42), we can set `amount` of `flashLoad` to be 0.
  - Receiver can call `pool.deposit` while [calling back to receiver](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/side-entrance/SideEntranceLenderPool.sol#L38).
    - [the ownership of the deposit can be assigned to receiver.](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/side-entrance/SideEntranceLenderPool.sol#L21)
    - the balance of pool have not changed.

### 2024.08.31

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- The Rewarder
  - [`claimRewards`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/the-rewarder/TheRewarderDistributor.sol#L81C14-L81C26) uses[`_setClaimed`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/the-rewarder/TheRewarderDistributor.sol#L120C14-L120C25) to prevent reclaiming based on \<token, sender, batchNumber\>.
  - However, `_setClaimed` is only called after token switch of `inputClaims` array.
  - So, before switching token, we can reclaim with same \<token, sender, batchNumber\>.

### 2024.09.01

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Selfie
  - If we want to take all the token inside `SelfiePool`
  - We should call [`SelfiePool.emergencyExit`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SelfiePool.sol#L71C14-L71C27)
  - To bypass the check of `SelfiePool.emergencyExit`, we should use [`SimpleGovernance.executeAction`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SimpleGovernance.sol#L53).
  - To execute an action, we should calling [`SimpleGovernance.queueAction`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SimpleGovernance.sol#L23C14-L23C25) first.
  - To call `SimpleGovernance.queueAction`, we should bypass the check of [`_hasEnoughVotes`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SimpleGovernance.sol#L100) which means we should get more than half of the voting token.
  - We can use [`SelfiePool.flashLoan`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SelfiePool.sol#L50C14-L50C23) to get the require token voting token.
  - Then, we can delegate the token and `SimpleGovernance.queueAction`.
  - Finally, we can return the token to SelfiePool.
  - After `ACTION_DELAY_IN_SECONDS`, we can call `SimpleGovernance.executeAction`.

### 2024.09.02

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Compromised

  - The basic attack vector is that we buy the nft with low price and sell it with high price.
  - So, we should manipulate oracle. Specifically, we should control two of the three price sources to manipulate [the median price](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/compromised/TrustfulOracle.sol#L59-L61).
  - The strange response from the server includes the base64 encoded private keys of two price sources.
  - With the private keys, we can manipulate the nft price oracle.

### 2024.09.03

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Puppet
  - We can manipulate [the oracle price](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/puppet/PuppetPool.sol#L59-L62) of PuppetPool to enable almost free borrow.
  - At first, We can sell the token for ETH to make `uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair)` small
  - Then, we [borrow](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/puppet/PuppetPool.sol#L30) all the token balance of PuppetPool with very few ETH.
  - Finally, we can sell ETH for the token to get back tokens which are used to manipulate the oracle price of PuppetPool.
  - Note: If we want to attack with only one transacation, we can
    - Deploy an `Attacker` contract
    - Attack inside the `constructor`
    - Pay ETH to `constructor`
    - Pay Token to `constructor` by `permit2`

### 2024.09.04

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Puppet V2
  - The attack vector is still exist like `Puppet`
  - The differences are
    - use WETH instead of ETH
    - use `IUniswapV2Router02`

### 2024.09.05

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Backdoor
  - We find that [`proxyCreated`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/backdoor/WalletRegistry.sol#L67) will ensure the [`setup`](https://github.com/safe-global/safe-smart-account/blob/bf943f80fec5ac647159d26161446ac5d716a294/contracts/Safe.sol#L95-L104) process is fine
  - So, we can check if there is something missed
  - We can see that <`to`, `data`> and <`paymentToken`, `payment`, `paymentReceiver`> are not checked.
  - However, `proxyCreated` is called after `setup`, so we do not have any token to transfer
  - Then, we can check the logic of `setupModules(to, data)`
  - Finally, we find that `delegate` call is allowed [here](https://github.com/safe-global/safe-smart-account/blob/bf943f80fec5ac647159d26161446ac5d716a294/contracts/base/ModuleManager.sol#L35-L39).
  - So, we can let the wallet approve the token to anyone by manipulate the <`to`, `data`> input.
  - Finally, we can use `transferFrom` to rug the token of the wallet.

<!-- Content_END -->
