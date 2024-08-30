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

## Naive Receiver (WIP)
This time, we are required to act as white-hat hackers to rescue the funds from both the pool and the receiver.

The receiver's contract is simpler, only having one function `onFlashLoan`.
By comparing the checks inside with previous task's, we can find that the receiver does not check the loan initiator!
So, we can easily drain receiver's funds by making it paying the flash loan fee.

Now the problem is how to drain the pool's funds.
`_msgSender()` and `Multicall` are suspicious in the pool, but I haven't found any vulnerabilities in the logic of the forwarder yet.
Leave it for a to-be-continued.


