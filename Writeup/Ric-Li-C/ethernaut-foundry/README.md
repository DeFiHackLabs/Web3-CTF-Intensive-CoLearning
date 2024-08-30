# Ethernaut Reforged 👩‍🚀🔨

This repo is a customized Foundry environment where devs can create/solve/submit ethernaut challenges without the need for interaction with the [Ethernaut CTF website](https://ethernaut.openzeppelin.com/). 

## Setup

- Have Foundry downloaded
- Clone this repo
- Copy the items in `.env.example` with your own credentials
- (Skipped) Open `/script/setup/EthernautHelper.sol` and edit the `HERO` variable to your own address
- Get some testnet eth (Sepolia is recommended as ether is easier to come by)

## Completing A Challenge

While the challenge contracts are part of the repo (`challenge-contracts`), it's recommended that you use interfaces when interacting with the challenge contracts to avoid issues compiling when requiring old solidity versions and older versions of OpenZeppelin contracts for some of the challenges.

When you think you've created the script that solves the challenge call the following:
```
source .env
forge script script/solutions/SCRIPT_FILE_NAME.s.sol:SCRIPT_CONTRACT_NAME --rpc-url $SEPOLIA_RPC
```

This will run a local simulation of your transaction off chain, if your script passes the challenge, run the same `forge script ...` command again but add `--broadcast` to broadcast the transaction(s) on chain.

## Further Updates

This repo is still a work in progress, and eventually all 29 of the Ethernaut challenges will be added. The description and hints from the ethernaut site for each challenge will be brought over as well as adding some extra resources based on the specific vulnerability the challenge highlights including educational content and real world examples.
