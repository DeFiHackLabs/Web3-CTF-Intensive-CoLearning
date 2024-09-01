# 0 - Hello Ethernaut writeup

## 题目
[Fallback](https://ethernaut.openzeppelin.com)

## 笔记
注意到如下函数，只需要通过钱包调用以下 Fal1out 函数，即可使自己的钱包成为 owner

```    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

在 console 中输入 await `contract.Fal1out({value:1})` 等待钱包确认交易即可
