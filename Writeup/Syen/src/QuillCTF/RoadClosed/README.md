## Road Closed

- 成为合约的所有者
- 将合约内的 `hacked` 字段改为 `true`

`addToWhitelist` 方法未进行 `owner` 检测。意味着所有人都可以加入 `whitelistedMinters`

`changeOwner` 方法要求地址必须在 `whitelistedMinters` 才能设置 `owner`, 结合 `addToWhitelist` 意味着任何人都可以成为 `owner`。

在成为 `owner` 后调用 `pwn` 即可将 `hacked` 字段更改为 `true`
