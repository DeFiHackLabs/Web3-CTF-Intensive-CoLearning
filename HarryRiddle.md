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

#### Ethernaut CTF (10/31)

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

- Description: `Force` contract does not have any fallback or receive methods to receive ether. We can force this contract to receive ether by using other contract to destruct itself:

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Force.t.sol")

**Vault**

- Description: This `Vault::password` is private so we can not read it. However, everything in blockchain is public, we will get it from storage of `Vault` contract.

- Proof of Code: There are 2 variable with `bool` and `bytes32` type storing at slot 0 and slot 1 in contract's memory because `bool` type is 32 bytes in slot 0 and `bytes32` is in slot 1 (each slot has 32 bytes itself).

```javascript
    bool public locked;
    bytes32 private password;
```

**King**

- Description: `King` contract is competitive contract with the `king` will be the last sending the biggest ether or be sent by `owner`. When other would be the `king`, they will send ether to this contract larger or equal the last `prize` and `King` contract will send back last `king` their ether. What happen if last `king` is a contract without fallback or receive methods? The last `king` will be the king forever.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/King.t.sol")

**Re-entrancy**

- Description: This `Reentrance` contract allows us to re-enter the `withdraw` function through other contract has receive or fallback methods containing `Reentrance::withdraw` call because the `Reentrance::donate` will send ether to the callee. The reason is that the `Reentrance` contract change the user's balance state after the invoker finished.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Reentrance.t.sol")

#### QuillCTF Challenges (0/23)

#### Real World CTF 2024 SafeBridge (0/1)

#### Paradigm CTF 2023 (0/17)

### 2024.08.30

#### Ethernaut CTF (11/31)

**Elevator**

- Description: Attack the `Elevator` contract by implementing the other contract with custom `isLastFloor` function.

- Proof of Code: [Testing]("/Writeup/HarryRiddle/Ethernaut-CTF/test/Elevator.t.sol")

**Privacy**

- Description:

- Proof of Code:

#### QuillCTF Challenges (0/23)

#### Real World CTF 2024 SafeBridge (0/1)

#### Paradigm CTF 2023 (0/17)
