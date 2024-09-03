## Confidential Hash

### 目标

- 找到 `aliceHash` 和 `bobHash` 的 `keccak256` 哈希值。

### 分析

合约内 `aliceHash` 和 `bobHash` 变量都是私有属性, 无法直接读取

```solidity
bytes32 private aliceHash = hash(ALICE_PRIVATE_KEY, ALICE_DATA);
bytes32 private bobHash = hash(BOB_PRIVATE_KEY, BOB_DATA);
```

但可以通过存储槽读取属性。只需要计算变量所在的位置即可。

- firstUser: 0 号存储槽
- alice_age: 1 号存储槽
- ALICE_PRIVATE_KEY: 2 号存储槽
- ALICE_DATA: 3 号存储槽
- aliceHash: 4 号存储槽, 因为 keccak256 得到的是 32 字节的数据

- secondUser: 5 号存储槽
- bob_age: 6 号存储槽
- BOB_PRIVATE_KEY: 7 号存储槽
- BOB_DATA: 8 号存储槽
- bobHash: 9 号存储槽, 因为 keccak256 得到的是 32 字节的数据

`foundry` 提供的作弊码 `vm.load` 可以直接读取目标地址的 `storage slot`

```solidity
bytes32 aliceHash = vm.load(
    address(confidentialHash),
    bytes32(uint256(4))
);
bytes32 bobHash = vm.load(
    address(confidentialHash),
    bytes32(uint256(9))
);
```
