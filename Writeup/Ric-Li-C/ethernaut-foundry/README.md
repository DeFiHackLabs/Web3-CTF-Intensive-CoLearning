# Ethernaut Reforged 👩‍🚀🔨

This repo is a customized Foundry environment where devs can create/solve/submit ethernaut challenges without the need for interaction with the [Ethernaut CTF website](https://ethernaut.openzeppelin.com/).

## Setup

-   Have Foundry downloaded
-   Clone this repo
-   Install forge-std library
-   Copy the items in `.env.example` with your own credentials
-   Get some Sepolia testnet eth

## Solution

The solution files are placed in script/solutions/ folder, run below command to check:

```
forge script script/solutions/SCRIPT_FILE_NAME.s.sol:SCRIPT_CONTRACT_NAME --rpc-url sepolia
```

This will run a local simulation of your transaction off chain, run the same `forge script ...` command again but add `--broadcast` to broadcast the transaction(s) on chain.
