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

<!-- Content_END -->
