---
timezone: Asia/Shanghai
---



# ret2basic.eth

1. 自我介绍

Security Engineer Intern @zksecurity. I do ZK + Solidity for work, red teaming + game hacking for hobby.

2. 你认为你会完成本次残酷学习吗？

Can't say no.

## Notes

<!-- Content_START -->

### 2024.08.29

I have done Ethernaut and DamnVulnerableDeFi before ([writeup](https://ret2basic.gitbook.io/ctfwriteup)).

Plan:

1. Solve the last 2 challs from onlyPwner
2. Solve paradigm ctf 2023 locally
3. Solve curta locally: https://github.com/fiveoutofnine/tardis

Today:
- Half way into Diversion: https://onlypwner.xyz/challenges/4.
- Tried to compile https://github.com/rebryk/profanity-brute-force on both Linux and Windows but failed.

### 2024.08.30

1. Wrote a PoC for Solidity assembly related bug during work
2. Wrapped up eWPT exam (web hacking)

### 2024.08.31

1. Investigated a ECDSA signature related issue during work
2. Worked on Taichi private audit

### 2024.09.01

1. Wrapped up Taichi private audit

### 2024.09.02

1. Solved onlyPwner Diversion

### 2024.09.03

1. Solved onlyPwner SEAL911

### 2024.09.04

1. Investigated an issue with calling external function within the same contract with `this` keyword, such as `this.functionCall()`. I found that the msg.sender during this call with be `address(this)`, not the EOA address who initiated the tx.
2. Investigated an issue with using `offset` to access a portion of calldata in solidity assembly block.

### 2024.09.05

1. Investigated a super-duper complex reentrancy issue during work

### 2024.09.06

1. Wrapped up onlyPwner. Now I solved all challs.

### 2024.09.07

1. Built a Claude 3.5 prompt bot for web3 ctf.
2. Half way into DamnVulnerableDefi Curvy Puppet.

### 2024.09.08

1. Solved two Milotruck challs: Meta Staking and Gnosis Unsafe.

<!-- Content_END -->
