# 17 - MagicNum

## 题目
攻击以下合约
```solidity
//You've uncovered an Alien contract. Claim ownership to complete the level.
//
//Things that might help
//
//Understanding how array storage works
//Understanding ABI specifications
//Using a very underhanded approach
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
bool public contact;
bytes32[] public codex;

modifier contacted() {
assert(contact);
_;
}

function makeContact() public {
contact = true;
}

function record(bytes32 _content) public contacted {
codex.push(_content);
}

function retract() public contacted {
codex.length--;
}

function revise(uint256 i, bytes32 _content) public contacted {
codex[i] = _content;
}
}
}
```

## 解题
本题考察点：
该合约存在数组下溢和任意存储写入的漏洞，以下是详细的漏洞分析和攻击步骤：

### 漏洞分析：

1. **数组长度下溢漏洞（Underflow）**：

    - 在 Solidity 0.5.0 中，对数组长度的递减操作 `codex.length--` 不会执行下溢检查。
    - 当 `codex.length` 为 0 时，调用 `retract()` 函数会使数组长度下溢，变为 `2^256 - 1`，即一个非常大的数。

2. **任意存储写入漏洞**：

    - Solidity 中动态数组的元素存储位置从 `keccak256(slot)` 开始，其中 `slot` 是数组长度存储的位置。
    - 对于 `codex` 数组，其元素存储起始位置为 `keccak256(2)`，因为 `codex` 的长度存储在存储槽位 2。
    - 当数组长度被下溢后，我们可以使用任意大的索引 `i`，通过 `codex[i]` 访问和修改任意的存储槽位。
    - 通过计算合适的索引 `i`，使得 `keccak256(2) + i == 0`，即可覆盖存储槽位 0，即合约的 `owner` 变量。

### 攻击步骤：

1. **调用 `makeContact()` 函数**：

    - 设置 `contact` 为 `true`，以便通过 `contacted` 修饰器的检查。

2. **调用 `retract()` 函数**：

    - 使 `codex.length` 下溢，变为 `2^256 - 1`，允许对数组使用任意大的索引。

3. **计算索引 `i`**：

    - 计算 `i = 2^256 - keccak256(1)`，以便使 `keccak256(1) + i == 0`。

4. **准备要写入的数据 `_content`**：

    - 将攻击者的地址左填充为 32 字节，即 `bytes32(uint256(uint160(msg.sender)))`。

5. **调用 `revise(i, _content)` 函数**：

    - 使用计算得到的索引 `i`，将 `_content` 写入到存储槽位 0，覆盖合约的 `owner` 变量。
   
Slot        Data
------------------------------
0             owner address, contact bool
1             codex.length
.
.
.
p             codex[0]
p + 1         codex[1]
.
.
2^256 - 2     codex[2^256 - 2 - p]
2^256 - 1     codex[2^256 - 1 - p]
0             codex[2^256 - p]  (overflow!)
### 攻击代码示例：

```solidity
// 假设攻击者的地址为 attackerAddress
bytes32 attackerAddressPadded = bytes32(uint256(uint160(attackerAddress)));

// 计算 i = 2^256 - keccak256(2)
uint256 i =type(uint256).max - uint256(keccak256(abi.encodePacked(uint256(1)))) + 1

// 执行攻击
alienCodex.makeContact();
alienCodex.retract();
alienCodex.revise(i, attackerAddressPadded);
```
通过chisel 运行：
➜ type(uint256).max - uint256(keccak256(abi.encodePacked(uint256(1)))) + 1
Type: uint256
├ Hex: 0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a
contract.revise("0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a","0x0000000000000000000000001234123412341234123412341234123412341234")


### 总结：

通过利用数组长度下溢漏洞，我们可以修改数组的长度，使其足够大，然后计算合适的索引，覆盖任意存储槽位，最终取得合约的所有权。

**注意**：此漏洞存在于早期版本的 Solidity（如 0.5.0），在较新的版本中，数组长度的下溢和上溢检查已经得到加强，类似的漏洞已被修复。

---

**关键点总结**：

- **数组长度下溢**：利用 `codex.length--` 在长度为 0 时下溢。
- **存储槽位计算**：动态数组元素的存储槽位计算方式为 `keccak256(slot) + index`。
- **覆盖存储槽位**：通过计算索引，使得目标槽位被覆盖，进而控制合约。