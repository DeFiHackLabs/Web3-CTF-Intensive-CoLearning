#!/bin/bash
cast send -r $RPC_OP_SEPOLIA $FALLBACK_INSTANCE "contribute()" --value 1wei --private-key $PRIV_KEY
cast send -r $RPC_OP_SEPOLIA $FALLBACK_INSTANCE --value 1wei --private-key $PRIV_KEY
cast send -r $RPC_OP_SEPOLIA $FALLBACK_INSTANCE "withdraw()" --private-key $PRIV_KEY