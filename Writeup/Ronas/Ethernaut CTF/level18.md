# Ethernaut CTF Writeup

## Level 18 MagicNumber

> 題目: https://ethernaut.openzeppelin.com/level/0x6F9cf195B9B4c1259E8FCe5b4e30F7142f779DeA

原始碼:
```
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

過關條件: 

- provide the Ethernaut with a Solver, a contract that responds to whatIsTheMeaningOfLife() with the right 32 byte number.
- The solver's code needs to be really tiny. Really reaaaaaallly tiny. Like freakin' really really itty-bitty tiny: 10 bytes at most.
- Hint: Perhaps its time to leave the comfort of the Solidity compiler momentarily, and build this one by hand O_o. That's right: Raw EVM bytecode.

解法：

- 根據提示 whatIsTheMeaningOfLife(), solver 必須回傳 42 `return bytes32(uint256(42));`
- 

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MagicNum} from "../src/level18/MagicNum.sol";

contract MagicNumSolver {
    constructor() {
        assembly {
            // 0x60     push1
            // 0x52     mstore
            // 0xf3     return

            // 602a     push 0x2a (=42) in stack (value param to MSTORE)
            // 6050     push 0x50 in stack (position param to MSTORE)
            // 52       store value (v=0x2a) at position (p=0x50) in memory
            // 6020     push 0x20 in stack (size param to RETURN)
            // 6050     push 0x50 (slot at which v=0x42 was stored)
            // f3       RETURN (value=0 of size (0x20)
            mstore(0, 0x602a60505260206050f3)
            return(0x16, 0x0a) // offset 0x16, length 0x20
        }
    }
}

contract Attack is Script {
    MagicNum target = MagicNum(payable(0x225534cf7dA8401ba119A62015FF87C7Eecaeb54));
    MagicNumSolver solver;
    function run() public {
        vm.startBroadcast();

        solver = new MagicNumSolver();
        target.setSolver(address(solver));

        vm.stopBroadcast();
    }
}

```