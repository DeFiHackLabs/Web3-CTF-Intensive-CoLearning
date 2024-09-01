## [Compromised](https://www.damnvulnerabledefi.xyz/challenges/compromised/)

> While poking around a web service of one of the most popular DeFi projects in the space, you get a strange response from the server. Here’s a snippet:
>
> ```
> HTTP/2 200 OK
> content-type: text/html
> content-language: en
> vary: Accept-Encoding
> server: cloudflare
> 
> 4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30
> 
> 4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
> ```
>
> A related on-chain exchange is selling (absurdly overpriced) collectibles called “DVNFT”, now at 999 ETH each.
>
> This price is fetched from an on-chain oracle, based on 3 trusted reporters: `0x188...088`, `0xA41...9D8` and `0xab3...a40`.
>
> Starting with just 0.1 ETH in balance, pass the challenge by rescuing all ETH available in the exchange. Then deposit the funds into the designated recovery account.

```solidity
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
```

### Analysis

If we decode the HTTP response from the challenge description, we get two private keys.

- [0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744](https://gchq.github.io/CyberChef/#recipe=From_Hex('Space')From_Base64('A-Za-z0-9%2B/%3D',true,false)&input=NGQgNDggNjcgMzMgNWEgNDQgNDUgMzEgNTkgNmQgNGEgNjggNGQgNmEgNWEgNmEgNGUgNTQgNDkgN2EgNGUgNmEgNjcgN2EgNTkgNmQgNWEgNmEgNGQgMzIgNTIgNmEgNGUgMzIgNGUgNmIgNTkgN2EgNTYgNmIgNGQgNTcgNDkgMzQgNTkgNTQgNDkgMzMgNGUgNDQgNTEgMzAgNGUgNDQgNjMgMzEgNGYgNTQgNjQgNmEgNWEgNmEgNTIgNmIgNTkgNTQgNDUgMzMgNGQgNDQgNTYgNmEgNWEgNmEgNWEgNmEgNGYgNTQgNmIgN2EgNGQgNDQgNTkgN2EgNGUgN2EgNTEgMzAg)

- [0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159](https://gchq.github.io/CyberChef/#recipe=From_Hex('Space')From_Base64('A-Za-z0-9%2B/%3D',true,false)&input=NGQgNDggNjcgMzIgNGYgNDcgNGEgNmIgNGQgNDQgNDkgNzcgNTkgNTcgNTEgNzggNGYgNDQgNWEgNjkgNGUgNmEgNTEgMzMgNTkgNTQgNTkgMzUgNGQgNTcgNGQgMzIgNTkgNTQgNTYgNmEgNGQgNDcgNGQgNzggNGUgNTQgNDkgMzUgNWEgNmEgNDkgNzggNWEgNTcgNGUgNmIgNGQgNDQgNmMgNmIgNTkgMzIgNGQgMzAgNGUgNTQgNDkgMzAgNGQgNTQgNTEgNzcgNGQgNmQgNDYgNmEgNGUgNmEgNDIgNjkgNTkgNTQgNGQgMzMgNGUgMzIgNGQgMzAgNGQgNTQgNTUgMzU)

We can get the address by using `cast wallet address [PRIVATE_KEY]` command.

```shell
> cast wallet address 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744
0x188Ea627E3531Db590e6f1D71ED83628d1933088
> cast wallet address 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159
0xA417D473c40a4d42BAd35f147c21eEa7973539D8
```

The addresses are the oracle sources, so we might be able to control the oracles.

```solidity
contract CompromisedChallenge is Test {
  // [...]
  address[] sources = [
      0x188Ea627E3531Db590e6f1D71ED83628d1933088,
      0xA417D473c40a4d42BAd35f147c21eEa7973539D8,
      0xab3600bF153A316dE44827e2473056d56B774a40
  ];
  // [..]
  }
```

#### `Exchange`

To solve the challenge, we must transfer all of the Ethers from the `exchange` to the `recovery` address. Therefore, let's investigate the `exchange` contract first. There are only two places where the transfer of Ethers occurs: `Exchange.buyOne` and `Exchange.sellOne`. The price of the NFT is determined by `oracle.getMedianPrice(token.symbol())`, so let's investigate the `oracle`.

```solidity
contract Exchange is ReentrancyGuard {
		// [...]
    function buyOne() external payable nonReentrant returns (uint256 id) {
        if (msg.value == 0) {
            revert InvalidPayment();
        }

        // Price should be in [wei / NFT]
        uint256 price = oracle.getMedianPrice(token.symbol());
        if (msg.value < price) {
            revert InvalidPayment();
        }

        id = token.safeMint(msg.sender);
        unchecked {
            payable(msg.sender).sendValue(msg.value - price);
        }

        emit TokenBought(msg.sender, id, price);
    }

    function sellOne(uint256 id) external nonReentrant {
        if (msg.sender != token.ownerOf(id)) {
            revert SellerNotOwner(id);
        }

        if (token.getApproved(id) != address(this)) {
            revert TransferNotApproved();
        }

        // Price should be in [wei / NFT]
        uint256 price = oracle.getMedianPrice(token.symbol());
        if (address(this).balance < price) {
            revert NotEnoughFunds();
        }

        token.transferFrom(msg.sender, address(this), id);
        token.burn(id);

        payable(msg.sender).sendValue(price);

        emit TokenSold(msg.sender, id, price);
    }

    receive() external payable {}
}

```

#### `TrustfulOracle`

We can use `TrustfulOracle.postPrice` to modify the `_pricesBySource` since we possess the private keys of the sources. We control two of the three sources, allowing us to control the median of the price and, consequently, the price of the NFT on the `exchange`. We can buy low and sell high to drain the `exchange`.

```solidity
contract TrustfulOracle is AccessControlEnumerable {
  // [...]
  // Source address => (symbol => price)
  mapping(address => mapping(string => uint256)) private _pricesBySource;
  // [...]
  function postPrice(string calldata symbol, uint256 newPrice) external onlyRole(TRUSTED_SOURCE_ROLE) {
    _setPrice(msg.sender, symbol, newPrice);
  }
  // [...]
  function _setPrice(address source, string memory symbol, uint256 newPrice) private {
    uint256 oldPrice = _pricesBySource[source][symbol];
    _pricesBySource[source][symbol] = newPrice;
    emit UpdatedPrice(source, symbol, oldPrice, newPrice);
  }
  // [...]
  function getMedianPrice(string calldata symbol) external view returns (uint256) {
    return _computeMedianPrice(symbol);
  }
  // [...]
  function _computeMedianPrice(string memory symbol) private view returns (uint256) {
    uint256[] memory prices = getAllPricesForSymbol(symbol);
    LibSort.insertionSort(prices);
    if (prices.length % 2 == 0) {
      uint256 leftPrice = prices[(prices.length / 2) - 1];
      uint256 rightPrice = prices[prices.length / 2];
      return (leftPrice + rightPrice) / 2;
    } else {
      return prices[prices.length / 2];
    }
  }
}
```

### Solution
See [Compromised.t.sol](./Compromised.t.sol#L77).