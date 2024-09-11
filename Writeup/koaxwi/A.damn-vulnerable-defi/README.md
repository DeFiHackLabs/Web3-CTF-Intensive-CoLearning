# Damn Vulnerable Defi Writeup

Unlike Ethernaut, which has a level factory contract to initialize each level and check the solve status,
Damn Vulnerable DeFi is doing everything in foundry's test scripts, and it does not have instances on public test networks.

In each test script, there are generally 5 parts:
- `modifier checkSolvedByPlayer()`: to append `_isSovled()` check after the user's solution.
- `function setUp()`: initialize the level according to the level's description.
- `function test_assertInitialState()`: check the initial state matches the description.
- `function test_...()`: left blank for the player to fill in the solution.
- `function _isSolved()`: check if the level is solved according to the description.

To check a solution, run `forge test --mp test/<challenge-name>/<ChallengeName>.t.sol`, or `forge test --mc <TestContractName>`, which is shorter.

## Unstoppable (24/08/29)
In this challenge, we need to halt the vault. Complicated as it seems, we only need to tamper some conditions in the requires.

We have the following codes:

```solidity
function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data)
    external
    returns (bool)
{
    ...
    uint256 balanceBefore = totalAssets();
    if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // enforce ERC4626 requirement
    ...
}
function totalAssets() public view override nonReadReentrant returns (uint256) {
    return asset.balanceOf(address(this));
}
function convertToShares(uint256 assets) public view virtual returns (uint256) {
    uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
}
```

Although not very sure about what the enforced "ERC4626 requirement" is, it checks that `totalSupply * totalSupply / totalAssets() == totalAssets()`.
This equation only works when `totalAssets() == totalSupply`. If we transfer 1 token to the vault to increase `totalAssets`, the equation no longer holds, and the require will revert.

Using `convertToShares` is a mistake, as the parameter name has indicated. It is used for converting assets to shares (total supply in this case).
There is actually another function called `convertToAssets`, which should be correct for this purpose.

## Naive Receiver (24/08/30)
This time, we are required to act as white-hat hackers to rescue the funds from both the pool and the receiver.

The receiver's contract is simpler, only having one function `onFlashLoan`.
By comparing the checks inside with previous task's, we can find that the receiver does not check the loan initiator!
So, we can easily drain receiver's funds by making it paying the flash loan fee.

Now the problem is how to drain the pool's funds.
`_msgSender()` and `Multicall` are suspicious in the pool.
In ethernaut, *Puzzle Wallet* is a challenge whose `multicall` is `payable`, and we can use deposit multiple times only costing one `msg.value`.
But in this case, the `multicall` is not `payable`, and for the deposit method, the pool is forwarding the value to WETH.
Therefore, we cannot use the same trick here.

Then we turn to `_msgSender()` check.
If the caller is the forwarder, the pool will take the last part of calldata as sender.
However, the forwarder has signature check which we cannot forge.

Considering the two points together, we suddenly realized `multicall` actually uses `delegatecall` to execute the function.
If we use the forwarder to call `multicall`, the caller address info will not be appended inside the `delegatecall` context!

Now that we can tamper with `_msgSender()`, we can withdraw from anyone's `deposit`.

Finally we can start to write the exploits. The checker only allows no more than two transactions, so we need to either leverage the `multicall`, or implement the exploit logic in a contract. We choose the former way, with only one transaction.
After that, we need to figure out how to sign the forwarder's transaction with foundry.
Check the code in subfolders for more details.

## Truster (24/08/30)
The challenge has similar requirements to the previous one. We need to rescue the funds from a pool within one transaction.

This pool doesn't follow any ERC standard, and is missing a lot of checks.
One important thing is that, the pool directly uses `target.functionCall(data);` for the loan callback without any limitation.
This means we can call any function in any contract, e.g. token's `approve` function.

Since the challenge requires only one transaction and there is no more `multicall`, we need a contract to do all the stuff.

## Side Entrance (24/08/31)
Rescue the funds from another pool. The pool is not complicated.
We can ask for a flash loan, and then deposit the loaned ETH back to the pool to increase our balances.
The deposit is also considered as the payback of the flash loan。
Then we can withdraw all the funds.

## The Rewarder (24/08/31)
This chanllenge contract is a reward distributor.
It records the reward amount and address in a merkle tree, and users can claim the reward by providing the proof.

However, the contract does not correctly mark the claimed rewards, and we can claim the reward of a same token multiple times until the reward is exhausted.
(Use `console.log` to confirm that the player address is eligible for the reward.)

## Selfie (24/09/01)
This challenge introduces a new concept: governance. Apparently, we need to call `emergencyExit` somehow.

The `SimpleGovernance` mainly has two functions: `queueAction` and `executeAction`.
The former is used to queue an action, and requires the caller's `getVotes` is greater than half of the total supply of the underlying token.
The latter is used to execute the action, and requires the action is queued for at least 2 days.

By checking the `ERC20Vote` contract, we find that to have votes, we need to call `delegate`, and our token balance will be used as voting uint.
As the pool is holding 75% of the total supply, we can ask for a flash loan to increase our voting power and queue the action.

For the 2 days check, we cannot find a way to bypass it.
Some thoughts: The governance contract uses `unchecked` to calculate the `timeDelta`, but we cannot propose an action at some future time.
After some searching, we use foundry's cheatcode to set the block timestamp.
There is `warp` to set the timestamp and `skip` to skip the time.

## Compromised (24/09/02)
In this challenge, we should hack an exchange for NFT.
The exchange only provides functions to buy and sell NFTs, and the price is determined by the oracles, basing on the prices provided by three EOA sources.

So, if we want to manipulate the price, we need the access to the source EOA, and we can buy NFTs at a lower price and sell them at a higher price afterwards.
The challenge provides two sets of hex characters. Unhexing and then base64 decoding them, we get the private keys of the two sources.
The following is straightforward then.

## Puppet (24/09/03)
In this challenge, there is a lending pool to hack.
The pool lends tokens, requiring the borrower to deposit twice the amount of ETH. (Actually there is no functions implemented to return tokens and withdraw ETH.)
The price is determined by a uniswap's balance.
We need to drain the pool's tokens.

The uniswap starts with 10 ETH and 10 DVT, and the player has 25 ETH and 1000 DVT.
So, we have far more assets than the uniswap, and we can manipulate the price by buying and selling tokens.
By simply transferring our initial tokens to uniswap, we can drastically decrease the price of DVT from 2:1 to 2:101.
But that is still not enough for our ETH balance to drain the pool.
We need to further decrease the price.

If we use uniswap to sell DVT for ETH, we will get `10 - 10 * 10 / 1010` (around 9.9) ETH from the uniswap.
Now uniswap has 0.1 ETH and 1010 DVT, therefore the price is 0.2:1010, and we can buy the pool's DVT at a lower price.

By the way:
1. The uniswap interface provided by the challenge is missing some `payable` modifier. [Ref](https://docs.uniswap.org/contracts/v1/reference/interfaces#solidity-1)
2. Seems the player nonce is only increased when constructing contracts in forge, not when executing(send) other transactions? And I think it is impossible to include every step in a single transaction.

## Puppet V2 (24/09/03)
Now the uniswap V1 is replaced with V2.
The puppet pool switches to use the uniswap library to the the price.

The uniswap has 10 WETH and 100 DVT, and the player has 20 ETH and 10000 DVT. The pool has 1M DVT.
The player's assets are still far more than the uniswap, and the V1 to V2 change does not resolve this problem.
Let's try to manipulate the price again by interacting with the uniswap V2.

It turns out that one swap is enough to decrease the price to what we can afford.
However, if we only buy part of the pool's DVT each time and swap them again, the price will continuely decrease.
The issue is that we need to swap back the DVT to WETH for the recovery, and there may be a tradeoff between the lower price and the extra swap fee.

## Free Rider (24/09/04)
This challenge provides a vulnerable NFT market.

An easy logical mistake is that, the market will transfer the price of NFT to `_token.ownerOf(tokenId)` after transferring the NFT, which means the owner is already changed from the seller to the buyer.
Another issue is, the market allows bulk offer and bulk buy. When buying multiple NTFs in a transaction, it reverts when `msg.value < priceToPay` for each token. So we only need to send the maximum of all prices, not the sum of them.

Now let's check the initial setup.
There are six NFT offers, all at the price 15 ETH.
That means if we have 15 ETH, we can send it to the market to "buy" all NFTs, and meanwhile the market will return 6*15 ETH to us.
However, we only holds 0.1 ETH at the beginning.

If there is some flash loan... - The uniswap in this challenge is exactlly for the rescue.
In [UniswapV2Pair](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol) there is a function `swap`.
The pair will first transfer tokens to the receiver, then call `uniswapV2Call` on the reveiver, and finally check whether the amount and fee is paid back.
By referring this [document](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps), we can implement an attacker contract to so.

## Backdoor (24/09/05 - 06)
This challenge introduces a new topic: multisignature wallet.
Although there is only one challenge source `WalletRegistry`, the deployer actually uses a lot of library contracts.

First starting with checking the `WalletRegistry` source code, we find that, we need to use `SafeProxyFactory::createProxyWithCallback` to callback the `proxyCreated` function, and the registry will check:
- the factory and singleton must be the specified ones
- the initializer data must be a `setup` call
- the multisignature wallet only has one owner - the pre-defined beneficiary
- the threshold is also `1`
- the wallet has no `fallbackManager`
Afterwards, the registry will send token to the wallet, and we need to transfer that token out.

Then there are a lot of source code to read.
The wallet itself is a `SafeProxy`, and every call is delegated to the `Safe` singleton.
`Safe` and other base contracts it inherits have all the logics for the multisignature wallet.
When deploying, the `initializer` will be used to call the setup methods.

Note that we can construct the wallet with the owner as the beneficiaries, and control other parameters as well.
Regardless of the registry's check, what can we do to get the token?
- Call the `proxyCreated` directly by ourself
- Deploy the wallet with different implentation (different factory, different singleton ...)
- Setup the wallet with two owners (beneficiary and us) and threshold `1`, and sign the transfer transaction by our keys
- Setup the wallet with `fallbackManager`, and it will be used as fallback method of `FallbackManager`

Since theses ways cannot work, we need a more thorough investigation about the wallet setup,
and we find that there is a deletagecall to `to` with `data`, which means we can let the wallet do anything!
At the initializing period, the wallet has no tokens yet, so we can make it to approve us to spend the tokens.
We can actually change the singleton to perform more actions.

There may be some tricks writing the delegated functions.
When approving, it is easier to put the addresses of the token and spender in the calldata.
Or, we can either hardcode the addresses or use `immutable` modifier to store them.
However, if we use keep the addresses in storage as usual, the wallet will cannot read from **its** storage.

## Climber (24/09/06)
In this challenge, there is a `ClimberVault` behind proxy, and a `ClimberTimelock` as the owner.

We start with checking the methods we can call:
- `ERC1967Proxy`: the only external method is the fallback method
- `ClimberVault`: all non-view public / external methods have modifier
- `ClimberVault`'s parent classes: `Initializable` has no public methods; `OwnableUpgradeable` and `UUPSUpgradeable` requires `onlyOwner`
- `ClimberTimelock`: we can call `execute`, and its implementation is weird

The `ClimberTimelock` works like `SimpleGovernance` in Selfie challenge.
Proposers can `schedule` operation, and after some delay everyone can trigger its execution.
The abnormal thing is, the `execute` method is asking all parameters about the operation, then it executes the operation, and finally checks the state after execution.
By making an illegal operation legal during the execution, we can call the vault as its owner.

If we execute random operations, the check will fail as its `known` is false, so it must be properly `schedule`d.
There is also a delay check, but we can update it to `0` during the execution.

We are thinking of scheduling the operation itself inside the operation at first,
but since scheduling uses exactly the calldata as execution, perhaps it requires some manipulation to pass the whole calldata to `schedule`?
What's more, `schedule` requires `PROPOSER_ROLE`. Though `ADMIN_ROLE` is proposer's admin role, it only means admins can manage propsers, rather than admins having proposers' capabilities.
Later we realized that we can instead grant the role to an attacker contract, and let the contract to schedule the operation.

When it comes to the vault part, even the owner cannot withdraw all tokens immediately.
However, since we can bypass `onlyOwner` of `_authorizeUpgrade`, we can just switch the vault's implementation, and do whatever we want.

## Wallet Minging (24/09/07)
In this challenge, we need to rescue funds from a contract `WalletDeployer` as well as another address of an un-deployed contract.

Start with code auditing. `TransparentProxy`, as a proxy, is having a storage variable `upgrader` at slot 0, whose position will easily collide with other variables the implemention.
In this case, the `AuthorizerUpgradeable` has `needsInit` at the same slot, indicating whether the contract can be initialized.

When `AuthorizerFactory` deploys the proxy with `AuthorizerUpgradeable`, the `upgrader` (as well as `needsInit`) will first be set as `msg.sender`, and then it will be set to `0` in `AuthorizerUpgradeable.init`.
`AuthorizerFactory` do check `needsInit` is zero, however it updates `upgrader` next, which also updates `needsInit`.
With this vulnerability, we can re-`init` the contract.

The `AuthorizerUpgradeable` is used in `WalletDeployer`'s `can` implementation, which is required in `drop`.
So we can deploy our `Safe` and get reward. 
Since one deployment is enough to drain the fund of `WalletDeployer`, we can rescue the fund together with the deposit wallet.

Therefore, the `Safe` address should be the user's deposit wallet.
The challenge allows us to use user's private key, so we can assume it is using a minimal setup (user as the only owner, threshold 1, all other parameter empty), and then bruteforce the `nonceSalt` to find the address.
If we are using other tools than `forge test`, we can directly **call** `createProxyWithNonce` to get the address, without actually deploying it.
But in the forge context, seems we cannot call functions without changing the state.

The `Safe` is deployed by `create2`, which has deterministic addresses at `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code))[12:]` ([Ref](https://eips.ethereum.org/EIPS/eip-1014)).
The test script has imported a library `Create2`, which provides the utility to calculate the address.
Note `salt` here is not `nonceSalt`.
After correctly providing the parameters, it turns out the nonce is `13`.
Finally, we can deploy the wallet, and sign a transfer transaction with user's private key.

Note: In realworld, we should hardcode the nonce and signature rather than finding / signing them at runtime. Otherwise, gas cost / secret key leakage.

## Puppet V3 (24/09/08)
Puppet pool again.

This time, the challenge specify a block (15450164) of main net ethereum to fork.
Still, the uniswap pool is newly deployed, with 100 WETH and 100 DVT.
The player holds 1 ETH and 110 DVT.

Before trying to manipulate the price again, we should learn the method of price calculation this time (especially `arithmeticMeanTick` in `_getOracleQuote`).
What's more, the tokens swapping interface of uniswap v3 also has something changed (`sqrtPriceLimitX96`).
A nice toturial about uniswap v3 here: https://uniswapv3book.com/

Since the uniswap pool's `swap` require the payment in callback (as what we were doing in Free Rider), we decided to leverage the router of main net (0xE592427A0AEce92De3Edee1F18E0157C05861564) to swap.
The router really eases the pain a lot! (e.g. `sqrtPriceLimitX96` can be zero)

Right after the swap, we have 101 ETH (-1 wei, to be exact), but the deposit required remains the same.
Using `skip` to fast forward the time, we can see the price is decreasing every second.
Skipping 70 seconds, we can afford the total deposit.

The uniswap v3 pool provides concentrated liquidity.
For a uniswap v2 pool holding 100 WETH and 100 DVT, we can swap 100 DVT for only 50 WETH (not considering fee).
For v3, we can swap them at the rate near `1:1`, as long as the liquidity is enough.
In the challenge setup, the deployer has set the tick range as `[-60, 60]`, which means the rate can be `1.006:1 ~ 1:1.006` (a tick is 0.01%).
If we try to swap all our tokens, the actual swap is 100.602242132672209194 DVT for 99.999999999999999999 WETH, approximately `1.006:1`.
The uniswap pool only has 1 wei WETH now.

Then why 70s?
It's still hard for me to understand how uniswap v3 works (about the observations)...

## ABI Smuggling (24/09/09)
A `SelfAuthorizedVault` implementing `AuthorizedExecutor`.
Both `withdraw` and `sweepFunds` of the vault require the caller is itself, therefore we directly go to check the `AuthorizedExecutor`.

There is an `execute` function where it can call itself as long as the caller has the premission to use the selector.
However, the way it fetches selector is vulnerable: `selector := calldataload(4 + 32 * 3)`.
The function signature is `execute(address target, bytes calldata actionData)`, and the normal calldata layout is:

```
0x00-0x04   selector (0x1cff79cd)
0x04-0x24   address target
0x24-0x44   offset of actionData (0x40)
0x44-0x64   length of actionData
0x64-....   actionData
```

By changing the offset, we can manipulate the real position of malicious `actionData`, and leave a legitimate one for the check.
If using `abi.encodeWithSelector`, things become easier as we only need to append the fake data.

## Shards (24/09/10)
Two major mistakes of the market:
1. Inconsistency between the amount to charge and refund.
```solidity
// fill
want.mulDivDown(_toDVT(price, rate), totalShards)           , or
want.mulDivDown(price.mulDivDown(rate, 1e6), totalShards)
// cancel
want.mulDivUp(rate, 1e6)
```
2. Incorrect check for TIME_BEFORE_CANCEL, buyers can cancel the order immediately after placing the order.
```solidity
if (
    purchase.timestamp + CANCEL_PERIOD_LENGTH < block.timestamp
        || block.timestamp > purchase.timestamp + TIME_BEFORE_CANCEL
) revert BadTime();
```

If we buy ~100 shards, the charge is 0 DVT.
However we can get refund by canceling it (75e11).
We can buy more shards with the refund, and canceling it will bankrupt the market.

## Curvy Puppet (24/09/10 ~ WIP)
Puppet lending pool once more.

We need to liquidate three users, which requires borrowed value grows larger than the collateral’s value.
Each user has 2500 DVT as collateral, valuing `25e23` according to the lending pool's rule (`getCollateralValue(collateralAmount) * 100`).
Each user borrows 1 LP Token, valuing `~7.68e23` (`getBorrowValue(borrowAmount) * 175`).
The oracle has fixed the price for DVT and ETH, while the value of an LP Token is `curvePool.get_virtual_price()` multiplied by the ETH price.
Therefore, we have to somehow enlarge the virtual price of the curve pool.

The source code of the curve is [here](https://github.com/curvefi/curve-contract/blob/master/contracts/pools/steth/StableSwapSTETH.vy).
The `curvePool.get_virtual_price` is determined by the pool's balance of ETH and stETH, and the total supply of the LP Token.
Adding or removing liquidity will only change the virtual price by a little bit.

A first thought is to transfer tokens to the curve without using `add_liquidity` method, so that its balances increase while the total supply remains.
But it requires huge amount of funds, and we cannot take the token back.

By reading [articles](https://www.chainsecurity.com/blog/curve-lp-oracle-manipulation-post-mortem), the read only reentrancy seems to be the solution.
The curve has two assets: native ETH and stETH.
During the removal the liquidity, the curve first burns the LP Token, then transfers the native ETH, and transfers stETH at last.
The moment when we receive the native ETH, the virtual price is higher, because the balance of stETH has not decreased yet.
With `remove_liquidity_imbalance`, we can even withdraw `1 wei` together with many stETH to further raise the virtual price.
After the removal finished, the virtual price falls back to the normal level.

First the trial starts with the cheat code `vm.deal`. We found that adding liquidity worthing ~170000 ether (in whatever division of assets, stETH has a `sumbit` method just similiar to `WETH.deposit`) and removing them is enough for the reentrancy attack to liquidate the users.
Then we need to find some flash loan to fullfill the whole attack.
We loaned 170000 WETH from multiple pools at first, and directly added the withdrawn ETH value to the curve's liquidity.
However, there are ~650 ETH missing (as admin fee) after the attack, let alone the loan fee.
A solution with cheat code [here](./Writeup/koaxwi/A.damn-vulnerable-defi/curvy-puppet/CurvyPuppetCheated.t.sol).

Later we found that the curve fee is affordable if we add liquidity using stETH.
(The curve will hold far more stETH than ETH, and we are also withdrawing lots of stETH with few ETH.)
But it is actually not easy to withdraw stETH back to ETH in a single transaction.
Seems we have to wait a few days before a normal withdraw? And there is nowhere to swap such a huge amount of funds.
Stuck at here. Perhaps we should directly flash loan some stETH ...? (Leave it for tomorrow)

