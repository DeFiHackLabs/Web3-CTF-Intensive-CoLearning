The core idea is to make the requirement `address(this).balance <= maxETH` fail to lead the execution of function `withdraw()` revert.

To achieve that, we should making the funds of the bank larger than maxETH (0.5ETH). One way is to use selfdestruct to make this happen. Therefore, we should create a contract and deposit funds, then destroy it, making the funds increase to be larger than 0.5ETH.