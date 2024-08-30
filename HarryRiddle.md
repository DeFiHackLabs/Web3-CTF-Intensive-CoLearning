---
timezone: Asia/Bangkok # Vietnam (UTC+7)
---

---

# HarryRiddle

1. 自我介绍

I'm 21 and studying Software Engineering at the University of Information Technology in Vietnam. I'm extremely curious and on passion of Blockchain. I'm willing to learn about blockchain, cryptography, security... and connect with others around the World.

2. 你认为你会完成本次残酷学习吗？

Never give up until i reach my last goal.

## Notes

Plan:

1. Solve the remaining parts of Ethernaut CTF and even QuillCTF Challenges bonus if i have much free time
2. Solve the Real World CTF 2024 SafeBridge
3. Solve the Paradigm CTF 2023

### 2024.08.29

#### Ethernaut CTF (6/31)

**Fallback**

- Description: The `Fallback` contract can be reclaimed ownership by anyone with fallback methods.

```javascript
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
@>      owner = msg.sender;
    }
```

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Fallback.t.sol")

**Fallout**

- Description: Incorrect in the old constructor name brings on reclaiming ownership.

```javascript
@>  function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

- Proof of Code: As the `Fallout` contract is lower than `0.8.0, i can not implement test in there. Just call `Fallout::Fal1out()` function to reclaim the ownership contract.

**Coin Flip**

- Description: `CoinFlip` contract use the random side of coin by `block.number`.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/CoinFlip.t.sol")

- Recommended: Using VRF instead.

**Telephone**

- Description: `tx.origin` and `msg.sender` should be different if we use the other contract to call `Telephone` contract.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Telephone.t.sol")

**Token**

- Description: Underflow / Overflow in version under `0.8.0`.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Token.t.sol")

- Recommended: Using `^0.8.0` version or `Safe Math` library.

**Delegation**

- Description: Careful of using delegate call.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Delegation.t.sol")

**Force**

**Vault**

**King**

**Re-entrancy**

**Elevator**

**Privacy**

#### QuillCTF Challenges (0/23)

#### Real World CTF 2024 SafeBridge (0/1)

#### Paradigm CTF 2023 (0/17)

### 2024.08.30
