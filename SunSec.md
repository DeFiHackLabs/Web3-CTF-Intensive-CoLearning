---
timezone: Asia/Taipei
---


# SunSec

1. 自我介绍
   
   [SunSec](https://x.com/1nf0s3cpt) Founder of DeFiHackLabs. 致力於安全教育和提升區塊鏈生態安全.
2. 你认为你会完成本次残酷学习吗？
   85%可以. 除非臨時任務太多XD 主要時間會花在協助大家完成共學.

## Notes

<!-- Content_START -->

### 2024.08.29

學習內容: 
- A 系列的 Ethernaut CTF, 之前做了差不多了. POC: [ethernaut-foundry-solutions](https://github.com/SunWeb3Sec/ethernaut-foundry-solutions)
- A 系列的 QuillAudit CTF 題目的網站關掉了, 幫大家收集了[題目](./Writeup/SunSec/src/QuillCTF/), 不過還是有幾題沒找到. 有找到題目的人可以在發出來.
- A 系列的 DamnVulnerableDeFi 有持續更新, 題目也不錯. [Damn Vulnerable DeFi](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0).
- 使用 [Foundry](https://book.getfoundry.sh/) 在本地解題目, 可以參考下面 RoadClosed 為例子
- ``forge test --match-teat testRoadClosedExploit -vvvv``
#### [QuillAudit CTF - RoadClosed](./Writeup/SunSec/QuillCTF/test/RoadClosed.t.sol)
```
  function addToWhitelist(address addr) public {
    require(!isContract(addr), "Contracts are not allowed");
    whitelistedMinters[addr] = true;
  }

  function changeOwner(address addr) public {
    require(whitelistedMinters[addr], "You are not whitelisted");
    require(msg.sender == addr, "address must be msg.sender");
    require(addr != address(0), "Zero address");
    owner = addr;
  }

  function pwn(address addr) external payable {
    require(!isContract(msg.sender), "Contracts are not allowed");
    require(msg.sender == addr, "address must be msg.sender");
    require(msg.sender == owner, "Must be owner");
    hacked = true;
  }

  function pwn() external payable {
    require(msg.sender == pwner);
    hacked = true;
  }
```
- 解決這個題目需要成為合約的 owner 和 hacked = true.
- On-chain: 可以透過 ``cast send`` 或是 forge script 來解.
- Local: 透過 forge test 通常是在local解題, 方便 debug.
- RoadClosed 為例子我寫了2個解題方式. testRoadClosedExploit 和 testRoadClosedContractExploit (因為題目有檢查msg.sender是不是合約, 所以可以透過constructor來繞過 isContract)
- [POC](./Writeup/SunSec/test/QuillCTF/RoadClosed.t.sol) 

### 2024.08.30
- DamnVulnerableDeFi #1 [Unstoppable](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#unstoppable)
- DamnVulnerableDeFi #2 [naive-receiver](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#naive-receiver)
- DamnVulnerableDeFi #3 [Truster](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#truster)

### 2024.08.31
- DamnVulnerableDeFi #4 [Side Entrance](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#side-entrance)
- DamnVulnerableDeFi #5 [The Rewarder](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#the-rewarder)
- DamnVulnerableDeFi #6 [Selfie](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#selfie)

### 2024.09.01
- DamnVulnerableDeFi #7 [Compromised](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#compromised)
- DamnVulnerableDeFi #8 [Puppet](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#puppet)
- DamnVulnerableDeFi #9 [Puppet V2](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#puppet-v2)

### 2024.09.02
- DamnVulnerableDeFi #10 [Free Rider](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#free-rider)
- DamnVulnerableDeFi #11 [Backdoor](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#backdoor)

### 2024.09.03
- DamnVulnerableDeFi #12 [Climber](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#climber)

### 2024.09.04
- DamnVulnerableDeFi #13 [Wallet Mining 還沒解完](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#wallet-mining-還沒解完)
- DamnVulnerableDeFi #14 [Puppet V3](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#puppet-v3)

### 2024.09.05
- DamnVulnerableDeFi #15 [ABI Smuggling](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#abi-smuggling)

### 2024.09.06
- DamnVulnerableDeFi #16 [Shards](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#shards)

### 2024.09.07
- DamnVulnerableDeFi #17 [Curvy Puppet](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#curvy-puppet)
- DamnVulnerableDeFi #18 [Withdrawal](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#withdrawal)

### 2024.09.08
- DamnVulnerableDeFi Recap

### 2024.09.09
- Grey Cat #1 [GreyHats Dollar](./Writeup/SunSec/greyhats-milotruck.md#greyhats-dollar)
- Grey Cat #2 [Escrow](./Writeup/SunSec/greyhats-milotruck.md#escrow)
- Damn - Wallet Mining - 可以透過create2算出user deposit wallet的nonce為13
- Damn - Curvy Puppet - 與作者確認後,題目沒有出錯. 需要使用multiple flashloan.

### 2024.09.10
- DamnVulnerableDeFi #13 solved [Wallet Mining](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#wallet-mining)
- Foundry computeCreate2Address.
- Create Safe wallet process.

### 2024.09.11
- DamnVulnerableDeFi #17 solved [Curvy Puppet](./Writeup/SunSec/damn-vulnerable-defi-writeup.md#curvy-puppet) writeup 最後再更新出來, 讓大家體驗一下殘酷.
- ✅ 完成 DamnVulnerableDeFi

### 2024.09.12
- Grey Cat #3 [Simple AMM Vault](./Writeup/SunSec/greyhats-milotruck.md#simple-amm-vault)
- Grey Cat #4 [Voting Vault](./Writeup/SunSec/greyhats-milotruck.md#voting-vault)
- Grey Cat #5 [Meta Staking](./Writeup/SunSec/greyhats-milotruck.md#meta-staking)

### 2024.09.13
- Grey Cat #6 [Gnosis Unsafe](./Writeup/SunSec/greyhats-milotruck.md#gnosis-unsafe)
- 出了兩個簡單題目for bootcamp [加分題](https://hackmd.io/@SunWeb3Sec/SJIZhzbaC)

### 2024.09.14
- warroom-ethcc-2023#1 [Proxy capture](./Writeup/SunSec/warroom-ethcc-2023.md#task-1---proxy-capture-15-points)
- warroom-ethcc-2023#2 [Flash loan](./Writeup/SunSec/warroom-ethcc-2023.md#task-2---flash-loan-25-points)
- warroom-ethcc-2023#3 [Signature malleability](./Writeup/SunSec/warroom-ethcc-2023.md#task-3---signature-malleability-30-points)

### 2024.09.16
- warroom-ethcc-2023#4 [Proxy capture](./Writeup/SunSec/warroom-ethcc-2023.md#task-4---access-control-35-points)
- warroom-ethcc-2023#5 [Metamorphic](./Writeup/SunSec/warroom-ethcc-2023.md#bonus-task---metamorphic-10-points)
  
<!-- Content_END -->
