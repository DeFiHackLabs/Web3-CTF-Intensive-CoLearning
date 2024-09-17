# Curvy Puppet

There's a lending contract where anyone can borrow LP tokens from Curve's stETH/ETH pool. To do so, borrowers must first deposit enough Damn Valuable tokens (DVT) as collateral. If a position's borrowed value grows larger than the collateral's value, anyone can liquidate it by repaying the debt and seizing all collateral.

The lending contract integrates with [Permit2](https://github.com/Uniswap/permit2) to securely manage token approvals. It also uses a permissioned price oracle to fetch the current prices of ETH and DVT.

Alice, Bob and Charlie have opened positions in the lending contract. To be extra safe, they decided to really overcollateralize them.

But are they really safe? That's not what's claimed in the urgent bug report the devs received.

Before user funds are taken, close all positions and save all available collateral.

The devs have offered part of their treasury in case you need it for the operation: 200 WETH and a little over 6 LP tokens. Don't worry about profits, but don't use all their funds. Also, make sure to transfer any rescued assets to the treasury account.

_NOTE: this challenge requires a valid RPC URL to fork mainnet state into your local environment._
