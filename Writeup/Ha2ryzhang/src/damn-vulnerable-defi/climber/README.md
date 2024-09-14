# Climber

There’s a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the [UUPS pattern](https://eips.ethereum.org/EIPS/eip-1822).

The owner of the vault is a timelock contract. It can withdraw a limited amount of tokens every 15 days.

On the vault there’s an additional role with powers to sweep all tokens in case of an emergency.

On the timelock, only an account with a “Proposer” role can schedule actions that can be executed 1 hour later.

You must rescue all tokens from the vault and deposit them into the designated recovery account.
