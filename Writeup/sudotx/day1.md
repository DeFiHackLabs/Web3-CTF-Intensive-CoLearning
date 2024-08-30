# Unstoppable

The goal is to halt flashloans on the unstoppable vault.

The system is made up of 2 contracts, the main vault and monitor. the main vault handles the flash loans while the monitor is the owner of the main vault and monitors its flashloan function for proper functioning

Since the vault uses the ERC-4626 standard its accounting is reliant on accounting of the shares and assets, my guess is to make the accounting inconsistent would likely break the internal accouting and brick the flash loan functionality. but i have been unable to crack that yet

## References

<https://eips.ethereum.org/EIPS/eip-3156>

<https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/>
