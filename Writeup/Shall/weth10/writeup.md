In this challenge, it first feels like we should do something with the flash loan. However, most of the functions are re-entrancy guarded, so we can't really get into them from within the loan. However, the loan logic itself allows us to call anything!

So, first we can have infinite allowance by making the contract itself call approve from within the loan, approving us a lot of tokens.

The real trick is in the second one, which is related to actually draining the funds. Let us examine the withdraw functions:

withdraw takes an amount, and sends it as value to the caller, and burns that same amount from the WETH10.
withdrawAll seems like it is doing a withdraw(<your-balance>) but it is not! At the burning step, it just burns your remaining token balance at that point! So, if you could somehow secure your tokens elsewhere right after receiving your withdrawals, but right before the burning takes place; then, you can retrieve those tokens later to keep withdrawing!
That is exactly what we will do. We first start with 1 ETH, so we can draw 1 ETH for free. Then, we can draw 2 ETH, and then 4 ETH and so on, until we drain the contract.