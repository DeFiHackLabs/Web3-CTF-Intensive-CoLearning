# 17 - MagicNum

## 题目
攻击以下合约
```solidity
//To solve this level, you only need to provide the Ethernaut with a Solver, a contract that responds to whatIsTheMeaningOfLife() with the right 32 byte number.
//
//Easy right? Well... there's a catch.
//
//The solver's code needs to be really tiny. Really reaaaaaallly tiny. Like freakin' really really itty-bitty tiny: 10 bytes at most.
//
//Hint: Perhaps its time to leave the comfort of the Solidity compiler momentarily, and build this one by hand O_o. That's right: Raw EVM bytecode.
//
//Good luck!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
address public solver;

constructor() {}

function setSolver(address _solver) public {
solver = _solver;
}

/*
____________/\\\_______/\\\\\\\\\_____        
 __________/\\\\\_____/\\\///////\\\___       
  ________/\\\/\\\____\///______\//\\\__      
   ______/\\\/\/\\\______________/\\\/___     
    ____/\\\/__\/\\\___________/\\\//_____    
     __/\\\\\\\\\\\\\\\\_____/\\\//________   
      _\///////////\\\//____/\\\/___________  
       ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
        ___________\///_____\///////////////__
*/
}
```

## 解题
本题考察点：
1. 如果要写opcodes ，需要写的两个部分包括 Initialization Opcodes 与 Runtime Opcodes。
OPCODE       NAME
------------------
0x60        PUSH1
0x52        MSTORE
0xf3        RETURN

目标是让_solver 合约返回 42 ，也就是 0x2a 。
Runtime Opcodes ：
602a (PUSH1 0x2a) 将值 0x2a 压入栈中。
6050 (PUSH1 0x50) 将内存位置 0x50 压入栈中。
52 (MSTORE) 从栈中弹出值 v = 0x2a 和位置 p = 0x50。 将值 0x2a 存储到内存位置 0x50 开始的 32 字节区域。
6020 (PUSH1 0x20) 将返回的数据大小 0x20（32 字节）压入栈中。 
6050 (PUSH1 0x50) 将返回的数据起始位置 0x50 压入栈中。
f3 (RETURN) 从栈中弹出位置 p = 0x50 和大小 s = 0x20。 返回从内存位置 0x50 开始的 32 字节数据。
602a60505260206050f3

Initialization Opcodes ：
OPCODE   DETAIL
-----------------------------------------
600a     10 字节
600c     从 Runtime Opcodes 在内存的位置读取数据
6000     将数据保存到内存的 0x00 位置
39       从 0x0c 位置读取 10 字节内容写入内存的 0x00 处
600a     将0x0a 入栈
6000     将0x00 入栈
f3       返回从内存位置 0x00 开始的 32 字节数据。
600a600c600039600a6000f3

使用 ethers.js 发送交易：

```typescript
    // 合约字节码
    const initializationOpcode = '600a600c600039600a6000f3';
    const runtimeOpcode = '602a60505260206050f3';
    const bytecode = initializationOpcode + runtimeOpcode;

    // 创建交易对象
    const transaction = {
        data: '0x' + bytecode
    };

    try {
        console.log("正在部署合约...");
        const tx = await wallet.sendTransaction(transaction);
        console.log("交易已发送，等待确认...");

        // 等待交易被确认
        const receipt = await tx.wait();
        console.log("合约已部署到地址:", receipt.contractAddress);

        return receipt.contractAddress;
    } catch (e) {
        console.log("发送交易时出错:", e);
    }
```

部署完成后，将地址填入 await contract.setSolver(solverAddr)，即完成挑战
