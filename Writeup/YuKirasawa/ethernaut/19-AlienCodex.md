旧版本的 solidity 允许修改 array 的 length 字段，且未进行下溢检查。因此可以将 length 溢出到最大值从而写任意地址。array 的首地址为 `keccak256(abi.encode(<slot id>))`，owner 变量对数组的下标为 `UINT256_MAX - uint256(keccak256(abi.encode(1))) + 1`
