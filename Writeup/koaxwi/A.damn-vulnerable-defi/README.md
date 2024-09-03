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

