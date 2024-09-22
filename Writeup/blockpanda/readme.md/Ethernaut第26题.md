### 第二十六题 DoubleEntryPoint
### 题目
找出 CryptoVault 中的错误位置，并保护它不被耗尽代币。
### 提示
- 代币合约的双入口是如何运行的？
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/access/Ownable.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

interface DelegateERC20 {
    function delegateTransfer(address to, uint256 value, address origSender) external returns (bool);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

contract Forta is IForta {
    mapping(address => IDetectionBot) public usersDetectionBots;
    mapping(address => uint256) public botRaisedAlerts;

    function setDetectionBot(address detectionBotAddress) external override {
        usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
    }

    function notify(address user, bytes calldata msgData) external override {
        if (address(usersDetectionBots[user]) == address(0)) return;
        try usersDetectionBots[user].handleTransaction(user, msgData) {
            return;
        } catch {}
    }

    function raiseAlert(address user) external override {
        if (address(usersDetectionBots[user]) != msg.sender) return;
        botRaisedAlerts[msg.sender] += 1;
    }
}

contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying;

    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
    }

    /*
    ...
    */

    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
    }
}

contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    DelegateERC20 public delegate;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}

contract DoubleEntryPoint is ERC20("DoubleEntryPointToken", "DET"), DelegateERC20, Ownable {
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    constructor(address legacyToken, address vaultAddress, address fortaAddress, address playerAddress) {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    modifier onlyDelegateFrom() {
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    modifier fortaNotify() {
        address detectionBot = address(forta.usersDetectionBots(player));

        // Cache old number of bot alerts
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // Notify Forta
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        if (forta.botRaisedAlerts(detectionBot) > previousValue) revert("Alert has been triggered, reverting");
    }

    function delegateTransfer(address to, uint256 value, address origSender)
        publicoverrideonlyDelegateFromfortaNotifyreturns (bool)
    {
        _transfer(origSender, to, value);
        return true;
    }
```
### 解题思路&过程
1. CryptoVault 的 sweepToken 可以将 vault 内除 underlying (DET) 以外的代币提走，LegacyToken (LGT) 代币的 transfer 被 delegate 给了 DoubleEntryPoint (DET) 代币，Forta 合约的 bot 可以实现对某些函数的 calldata 的检测, 当满足一定条件时会 alert (回滚交易)。
2.  CryptoVault 的 sweepToken 被设计成不能够提出 DET, 但是如果将 token 的地址指定为 LGT, 那么就可以通过一系列的函数调用, 最终将 vault 内的所有 DET 代币提走, 我们需要编写一个 detection bot 以阻止这种攻击
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// ...
contract DetectionBot is IDetectionBot {    
    IForta forta;    CryptoVault vault;
    constructor(address _forta, address _vault) {        
        forta = IForta(_forta);        
        vault = CryptoVault(_vault);    }
    function handleTransaction(address user, bytes calldata msgData) external {        
        (, , address origSender) = abi.decode(msgData[4:], (address, uint256, address));        
        if (origSender == address(vault)) {            
            forta.raiseAlert(user);        
            }   
        } 
}
```
