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

### 2024.09.02

(1) BlazCTF Maze challenge

Link: https://github.com/fuzzland/blazctf-2023/tree/main/challenges/maze

Writeup: The contract is written in pure Yul and utilizes Verbatim to generate bytecode for opcodes not defined by the Yul compiler. Our goal is to escape the Maze, but each attempt to move downward results in moving upward due to a bug in Verbatim mode, which restricts downward movement to twice only (see the restriction in not(iszero(sload(0xe)))). Consequently, we must find a path that requires moving downward fewer than two times.

(2) DamnVulnerableDeFi V4 Free Rider Challenge

Link: https://www.damnvulnerabledefi.xyz/challenges/free-rider/

Writeup: The `buyMany` function calls the internal `_buyOne` function to check that the input ether is sufficient by examining `msg.value`. However, `msg.value` is used consistently throughout the transaction, allowing an attacker to submit less ether and acquire all the NFTs. Although the attacker might initially lack sufficient funds, they can borrow through Uniswap and repay later.

### 2024.09.03

(1) DamnVulnerableDeFi V4 Unstoppable Challenge

Link: https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/unstoppable

Writeup: Our objective is to pause the vault and invoke the ownership transfer of the vault contract. This can only be achieved by failing to request a flash loan in `UnstoppableVault::flashLoan`. There is a requirement in the flash loan function, that `convertToShares(totalSupply)` should equal to `balanceBefore` value; if not, the transaction will revert. However, `balanceBefore` can be manipulated by directly depositing tokens into the vault contract, making the two values inequivalent.

### 2024.09.04

(1) Ethernaut Force Challenge

Link: https://ethernaut.openzeppelin.com/level/0xb6c2Ec883DaAac76D8922519E63f875c2ec65575

Writeup: Although a contract does not have `receive` and `fallback` to accept ether deposit, user can still force the contract to accept ether by `selfdesturct` low level call to transfer ether to the destination contract.

(2) Ethernaut Vault Challenge

Link: https://ethernaut.openzeppelin.com/level/0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670

Writeup: The state variable with private visibility can still be queried on blockchain, in the vault contract, we can simply calculate the storage slot of the state variable and check the corresponding value using Alchemy Composer.

### 2024.09.05

(1) DamnVulnerableDeFi V4 Naive Receiver Challenge

Link: https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/naive-receiver

Writeup: The vulnerability stems from how ERC-2771 and multicall are implemented in older OpenZeppelin versions, where msg.sender is extracted from the last 20 bytes of the call data. An attacker can exploit this by appending an address to the call data, thereby manipulating the msg.sender value.

### 2024.09.06

(1) Ethernaut Preservation Challenge

Link: https://ethernaut.openzeppelin.com/level/0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed

Writeup: There is a delegatecall vulnerability in the contract. When the `setFirstTime` and `setSecondTime` functions are invoked, the `timeZone1Library` and `timeZone2Library` data are altered, respectively. An attacker can update the `timeZone1Library` address to a malicious address, causing a delegatecall to the malicious LibraryContract, which can then transfer ownership of the Preservation contract.

### 2024.09.07

(1) Ethernaut King Challenge

Link: https://ethernaut.openzeppelin.com/level/0x3049C00639E6dfC269ED1451764a046f7aE500c6

Writeup: First create a contract to become the king, without `receive` or `fallback` functions. If another user attempts to become the `king` by sending ether, the transaction will revert, causing a Denial of Service issue.

### 2024.09.09

(1) Link Reentrancy Challenge

Link: https://ethernaut.openzeppelin.com/level/0x2a24869323C0B13Dff24E196Ba072dC790D52479

Writeup: The contract fails to follow the Check-Effect-Interaction (CEI) pattern and lacks a reentrancy lock in the `Reentrance::withdraw` function. Consequently, an attacker can recursively re-enter the function through a fallback or receive function, allowing them to drain the contract's balance.

<!-- Content_END -->
