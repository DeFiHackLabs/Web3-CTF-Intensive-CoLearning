---
timezone: Asia/Taipei
---


# SunSec

1. 自我介绍
   
   [SunSec](https://x.com/1nf0s3cpt), Founder of DeFiHackLabs. 致力於安全教育和提升區塊鏈生態安全.
3. 你认为你会完成本次残酷学习吗？
   85%可以. 除非臨時任務太多XD

## Notes

<!-- Content_START -->

### 2024.08.26

學習內容: 
- Ethernaut CTF, 之前做了差不多了, 不過沒寫紀錄. 之後再回頭來看看. POC: [ethernaut-foundry-solutions](https://github.com/SunWeb3Sec/ethernaut-foundry-solutions)
- A 系列我選擇 QuillAudit CTF 開始
  
#### [QuillAudit CTF - RoadClosed](./Writeup/SunSec/src/QuillCTF/RoadClosed.sol)
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
- 可以直接透過 ``cast send`` 或是 forge script 來解. forge test 通常是在local解題, 方便debug.
- 解題我寫了2方式. testRoadClosedExploit 和 testRoadClosedContractExploit (因為題目有檢查msg.sender是不是合約, 所以可以透過constructor來讓isContract)
- POC: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/blob/main/Writeup/SunSec/foundry.md

### 2024.08.30

<!-- Content_END -->
