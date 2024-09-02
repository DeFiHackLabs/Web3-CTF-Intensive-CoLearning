---
timezone: Asia/Taipei
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

# {你的名字}

1. Web3 Security Researcher
2. 你认为你会完成本次残酷学习吗？ Yes

## Notes

<!-- Content_START -->

### 2024.08.29

(1) BlazCTF easy-nft challenge

Link: https://github.com/fuzzland/blazctf-2023/tree/main/challenges/eazy-nft

Writeup: The `player` can call mint function and update the owner of a certain token through `ET:mint` function.

(2) BlazCTF lockless-swap challenge

Link: https://github.com/fuzzland/blazctf-2023/tree/main/challenges/lockless-swap

Writeup: The reentrancy lock is not implemented in the PancakeSwap function, allowing an attacker to call the swap function and synchronize the reserve in the callback function, followed by minting liquidity tokens. Through a series of similar operations, the attacker can retrieve most of the liquidity in the pool.

### 2024.08.30

(1) BlazCTF Jambo challenge

Link: https://github.com/fuzzland/blazctf-2023/tree/main/challenges/jambo

Writeup: After decompilation, we observed that the value at storage slot 1 is initialized to the parameter: ```0x66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64```. The setup function later calls ```revokeOwnership()```, but this call appears to have no impact. Upon analyzing the implementation of the answer function, we discovered that the input value must match the value at storage slot 0, and ```msg.value`` should exceed 1. Additionally, the function checks whether the caller is a contract. To bypass this check, we can initiate the attack within a constructor or by calling the contract from an EOA.

(2) BlazCTF rock-paper-scissor challenge

Link: https://github.com/fuzzland/blazctf-2023/tree/main/challenges/rock-paper-scissor

Writeup: This is a straightforward pseudo-randomness vulnerability. By analyzing the `randomShape` function, we can determine the outcome and provide a specific input to exploit the contract.

### 2024.08.31

(1) DamnVulnerableDeFi V4 side-entrance challenge

Link: https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/side-entrance

Writeup: there is reentrancy issue in the SideEntranceLenderPool, user can request flashloan and later deposit the borrowed asset into the pool when executing the callback function. Reentrancy lock is required to prevent such vulnerability.

(2) DamnVulnerableDeFi V4 Truster challenge

Link: https://www.damnvulnerabledefi.xyz/challenges/truster/

Writeup: it is the arbitrary call vulnerability, attacker can forge a malicious calldata for the flash loan provider to approve allowance to the attacker, and after the flash loan is repaid, the attacker can withdraw the asset through `transferFrom`.

<!-- Content_END -->