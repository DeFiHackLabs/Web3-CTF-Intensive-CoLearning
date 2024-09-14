---
timezone: Pacific/Auckland
---

> 请在上边的 timezone 添加你的当地时区，这会有助于你的打卡状态的自动化更新，如果没有添加，默认为北京时间 UTC+8 时区
> 时区请参考以下列表，请移除 # 以后的内容

timezone: Pacific/Honolulu # 夏威夷-阿留申标准时间 (UTC-10)

timezone: America/Anchorage # 阿拉斯加标准时间 (UTC-9)

timezone: America/Los_Angeles # 太平洋标准时间 (UTC-8)

timezone: America/Denver # 山地标准时间 (UTC-7)

timezone: America/Chicago # 中部标准时间 (UTC-6)

timezone: America/New_York # 东部标准时间 (UTC-5)

timezone: America/Halifax # 大西洋标准时间 (UTC-4)

timezone: America/St_Johns # 纽芬兰标准时间 (UTC-3:30)

timezone: America/Sao_Paulo # 巴西利亚时间 (UTC-3)

timezone: Atlantic/Azores # 亚速尔群岛时间 (UTC-1)

timezone: Europe/London # 格林威治标准时间 (UTC+0)

timezone: Europe/Berlin # 中欧标准时间 (UTC+1)

timezone: Europe/Helsinki # 东欧标准时间 (UTC+2)

timezone: Europe/Moscow # 莫斯科标准时间 (UTC+3)

timezone: Asia/Dubai # 海湾标准时间 (UTC+4)

timezone: Asia/Kolkata # 印度标准时间 (UTC+5:30)

timezone: Asia/Dhaka # 孟加拉国标准时间 (UTC+6)

timezone: Asia/Bangkok # 中南半岛时间 (UTC+7)

timezone: Asia/Shanghai # 中国标准时间 (UTC+8)

timezone: Asia/Taipei # 台灣标准时间 (UTC+8)

timezone: Asia/Tokyo # 日本标准时间 (UTC+9)

timezone: Australia/Sydney # 澳大利亚东部标准时间 (UTC+10)

timezone: Pacific/Auckland # 新西兰标准时间 (UTC+12)

---

# doublespending

1. 自我介绍 Doublespending
2. 你认为你会完成本次残酷学习吗？Yes

## Notes

<!-- Content_START -->

### 2024.08.29

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- UnstoppableVault
  - `UnstoppableMonitor.onFlashLoan` revert when [`convertToShares(totalSupply) != balanceBefore`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableVault.sol#L85C13-L85C58)
  - We can get the share amount by `convertToShares(totalSupply)`
  - In normal case, share amount equals to asset amount by `deposit` or `mint` method.
  - However, if we transfer the token to the pool directly, the share amount does not changed but the asset amount increases.
- NaiveReceiver
  - We can send all weth of `IERC3156FlashBorrower receiver` to `feeReceiver` by calling [flashLoan](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L43C24-L43C54) 10 times
  - Then, we use `Forwrarder` to call `Multicall` with a `withdraw` call.
  - [In this case, `msg.sender` is `Forwarder` and the pool will use the last 20 bytes as the `sender`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L87)
  - So, we can append `feeReceiver` to the `withdraw` call to act as `feeReceiver`.

### 2024.08.30

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Truster
  - [`target.functionCall(data)`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/truster/TrusterLenderPool.sol#L28) can be a `token.approve(player, TOKENS_IN_POOL)` call.
  - To by pass [the balance check](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/truster/TrusterLenderPool.sol#L30), we can set `amount` of `flashLoad` to be 0
  - Finally, palyer can use `token.transferFrom` to rescue all funds in the pool.
- Side Entrance
  - To by pass [the balance check](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/side-entrance/SideEntranceLenderPool.sol#L40-L42), we can set `amount` of `flashLoad` to be 0.
  - Receiver can call `pool.deposit` while [calling back to receiver](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/side-entrance/SideEntranceLenderPool.sol#L38).
    - [the ownership of the deposit can be assigned to receiver.](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/side-entrance/SideEntranceLenderPool.sol#L21)
    - the balance of pool have not changed.

### 2024.08.31

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- The Rewarder
  - [`claimRewards`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/the-rewarder/TheRewarderDistributor.sol#L81C14-L81C26) uses[`_setClaimed`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/the-rewarder/TheRewarderDistributor.sol#L120C14-L120C25) to prevent reclaiming based on \<token, sender, batchNumber\>.
  - However, `_setClaimed` is only called after token switch of `inputClaims` array.
  - So, before switching token, we can reclaim with same \<token, sender, batchNumber\>.

### 2024.09.01

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Selfie
  - If we want to take all the token inside `SelfiePool`
  - We should call [`SelfiePool.emergencyExit`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SelfiePool.sol#L71C14-L71C27)
  - To bypass the check of `SelfiePool.emergencyExit`, we should use [`SimpleGovernance.executeAction`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SimpleGovernance.sol#L53).
  - To execute an action, we should calling [`SimpleGovernance.queueAction`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SimpleGovernance.sol#L23C14-L23C25) first.
  - To call `SimpleGovernance.queueAction`, we should bypass the check of [`_hasEnoughVotes`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SimpleGovernance.sol#L100) which means we should get more than half of the voting token.
  - We can use [`SelfiePool.flashLoan`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/selfie/SelfiePool.sol#L50C14-L50C23) to get the require token voting token.
  - Then, we can delegate the token and `SimpleGovernance.queueAction`.
  - Finally, we can return the token to SelfiePool.
  - After `ACTION_DELAY_IN_SECONDS`, we can call `SimpleGovernance.executeAction`.

### 2024.09.02

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Compromised

  - The basic attack vector is that we buy the nft with low price and sell it with high price.
  - So, we should manipulate oracle. Specifically, we should control two of the three price sources to manipulate [the median price](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/compromised/TrustfulOracle.sol#L59-L61).
  - The strange response from the server includes the base64 encoded private keys of two price sources.
  - With the private keys, we can manipulate the nft price oracle.

### 2024.09.03

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Puppet
  - We can manipulate [the oracle price](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/puppet/PuppetPool.sol#L59-L62) of PuppetPool to enable almost free borrow.
  - At first, We can sell the token for ETH to make `uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair)` small
  - Then, we [borrow](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/puppet/PuppetPool.sol#L30) all the token balance of PuppetPool with very few ETH.
  - Finally, we can sell ETH for the token to get back tokens which are used to manipulate the oracle price of PuppetPool.
  - Note: If we want to attack with only one transacation, we can
    - Deploy an `Attacker` contract
    - Attack inside the `constructor`
    - Pay ETH to `constructor`
    - Pay Token to `constructor` by `permit2`

### 2024.09.04

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Puppet V2
  - The attack vector is still exist like `Puppet`
  - The differences are
    - use WETH instead of ETH
    - use `IUniswapV2Router02`

### 2024.09.05

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Backdoor
  - We find that [`proxyCreated`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/backdoor/WalletRegistry.sol#L67) will ensure the [`setup`](https://github.com/safe-global/safe-smart-account/blob/bf943f80fec5ac647159d26161446ac5d716a294/contracts/Safe.sol#L95-L104) process is fine
  - So, we can check if there is something missed
  - We can see that <`to`, `data`> and <`paymentToken`, `payment`, `paymentReceiver`> are not checked.
  - However, `proxyCreated` is called after `setup`, so we do not have any token to transfer
  - Then, we can check the logic of `setupModules(to, data)`
  - Finally, we find that `delegate` call is allowed [here](https://github.com/safe-global/safe-smart-account/blob/bf943f80fec5ac647159d26161446ac5d716a294/contracts/base/ModuleManager.sol#L35-L39).
  - So, we can let the wallet approve the token to anyone by manipulate the <`to`, `data`> input.
  - Finally, we can use `transferFrom` to rug the token of the wallet.

### 2024.09.06

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Free Rider

  - ## From [here](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/free-rider/FreeRiderNFTMarketplace.sol#L108), we can buy nft for free
    - `payable(_token.ownerOf(tokenId)).sendValue(priceToPay)` actually pay to the new owner (i.e. msg.sender) instead of the previous owner
  - However, we need to have enough ETH to bypass the check [here](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/free-rider/FreeRiderNFTMarketplace.sol#L97) when buying the first NFT.
  - We find that we can use [the flashswap of uniswap v2](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)
    - Put the above logic inside `uniswapV2Call`

### 2024.09.07

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Climber
  - If we want to transfer all token of `ClimberVault`, we have three potential choices:
    - `withdraw`: `onlyOwner`
    - `sweepFunds`: `onlySweeper`
    - `upgradeToAndCall`: `onlyOwner`
  - `sweeper` can only be set while [initialize](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/climber/ClimberVault.sol#L42). It is unlikely compromised.
  - `owner` is the `ClimberTimelock`. It is more likely compromised. Then, `upgradeToAndCall` is more dangerous than `withdraw`
  - So, we need `ClimberTimelock` to call `upgradeToAndCall`. We must call [`execute`](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/climber/ClimberTimelock.sol#L72) in this case.
- It seem that we actor as `ClimberTimelock` itself to do arbitrary call including `upgradeToAndCall` until the check [here](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/climber/ClimberTimelock.sol#L94)
- To bypass the check
  - We should make scheduled operation can be executed immediatedly. So, we can update dely to zero [here](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/climber/ClimberTimelock.sol#L101).
  - We should call `schedule`.
    - [For `address(this)` is the role admin of `PROPOSER_ROLE`](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/climber/ClimberTimelock.sol#L35). We can update `PROPOSER_ROLE` to malicious contract.
    - We can call the malicious contract and let it schedule the executions.

### 2024.09.08

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Wallet Mining
  - At first we should find the nonce that match the `USER_DEPOSIT_ADDRESS`. After brute-force method, we find that `nonce` equals to 13
  - Then, we should bypass [`can(msg.sender, aim)`](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/WalletDeployer.sol#L47)
  - It's weired that we actually can [reinit](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/AuthorizerUpgradeable.sol#L15) the `AuthorizedUpgradeable` for the misuse of the slots under `TransparentProxy`
    - When the proxy calls the init method of `AuthorizedUpgradeable`, `needsInit` is actually the first slot of `TransparentProxy` (e.g. [`upgrader`](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/TransparentProxy.sol#L13)) instead of the first slot of `AuthorizedUpgradeable` (e.g. [`needsInit`](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/AuthorizerUpgradeable.sol#L6C20-L6C29)).
    - At first, `upgrader` is `msg.sender`. So, we can bypass the check [here](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/AuthorizerUpgradeable.sol#L16).
    - Then, `AuthorizerFactory` will [set `upgrader` to zero address](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/AuthorizerUpgradeable.sol#L20)
    - Finally, `upgrader` is [set to non-zero address again](https://github.com/doublespending/damn-vulnerable-defi-v4-solutions/blob/77e3e6b700fd00f4c06e951cfac67e305c427a35/src/wallet-mining/AuthorizerFactory.sol#L20). So, we can reinit.

### 2024.09.09

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- ABI Smuggling

  - The key is to bypass [the selector check](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/abi-smuggling/AuthorizedExecutor.sol#L48-L56) when `exeucte`

    ```
        bytes4 selector;
        uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins
        assembly {
            selector := calldataload(calldataOffset)
        }

        if (!permissions[getActionId(selector, msg.sender, target)]) {
            revert NotAllowed();
        }
    ```

  - The above implemtation to fetch `selector` is not correct. For, the data of `actionData` is not required to follow the `offset` of `actionData`. The right approach to fetch `selector` is according to the `offset`.
  - So, we can add malicious data following the `offset` and let the above code fetch wrong selector which is approved to player.
  - Then, we set `offset` to skip the malicious data and point to the real selector which will be executed [here](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/abi-smuggling/AuthorizedExecutor.sol#L60).

### 2024.09.10

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Puppet V3
  - The attack vector is the same as `Puppet` and `Puppet V2`
  - The differences are
    - Uniswap v3 oracle will prevent price manipulation in the same block. So, we should call `lendingPool.borrow` in the future block.
    - use `ISwapRouter` of Uniswap V3

### 2024.09.11

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Shards

  - First, we can buy shards for free becase the required token can be zero in case `want * _toDVT(offer.price, _currentRate) < offer.totalShards`. We find the max number of free shards is 133.
  - Then, we can cancel immediately because of [the incorrect timestamp check](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/shards/ShardsNFTMarketplace.sol#L152-L155)
  - Again, there is also incorrect calculation of refund token [here](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/shards/ShardsNFTMarketplace.sol#L163).
  - We can keep calling `fill` and `cancel` to fetch all the token of `ShardsNFTMarketplace`.

### 2024.09.12

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

- Withdrawal
  - As a operator, we can invoke [arbitrary withdrawal](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/withdrawal/L1Gateway.sol#L47-L54) to secure all the token inside l1 bridge.
  - Then, we should leave enough token to l1 bride for 3 noraml withdrawals and not enough token for 1 suspicious withdrawal with pretty large amount.
  - [Then, after the `DELAY`, we can finalize the 4 withdrawals.](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/withdrawal/L1Gateway.sol#L42)
    - The 3 normal withdrawals can receive the token
    - The 1 suspicous withdrawals cannot recevie the token for the l1 bridge does not have enough token.
    - No matter if the reciver can receive the token, the withdrawals will [finalized](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/withdrawal/L1Gateway.sol#L59-L69).
  - Finally, we should return the token back to the l1 bridge.

### 2024.09.13

A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18) **DONE**

- CurvyPuppet
  - [Curve LP Oracle Manipulation: Post Mortem](https://www.chainsecurity.com/blog/curve-lp-oracle-manipulation-post-mortem)
    - [Resources]
      - [Mai Finance’s Oracle Manipulation Vulnerability Explained](https://medium.com/amber-group/mai-finances-oracle-manipulation-vulnerability-explained-55e4b5cc2b82)
      - [How to solve](https://github.com/code-423n4/2022-01-dev-test-repo-findings/issues/195)
  - We can manipulate the curve pool using fund from [aave flashloan](https://docs.aave.com/developers/guides/flash-loans)

<!-- Content_END -->
