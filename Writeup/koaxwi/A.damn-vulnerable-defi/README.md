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
