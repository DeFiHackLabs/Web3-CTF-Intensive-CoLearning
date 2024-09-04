#!/bin/bash
THE_PASSWORD=`cast storage "$VAULT_INSTANCE" 1 -r "$RPC_OP_SEPOLIA"
cast send -r $RPC_OP_SEPOLIA $VAULT_INSTANCE "unlock(bytes32)" $THE_PASSWORD --private-key $PRIV_KEY