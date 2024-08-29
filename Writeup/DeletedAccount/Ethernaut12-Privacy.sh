#!/bin/bash
key=$(cast storage $PRIVACY_INSTANCE 5 -r $RPC_OP_SEPOLIA | cut -c1-34) # 取出 bytes16 需要取前 34 個字串，因為輸出含前綴 0x
cast send -r $RPC_OP_SEPOLIA $PRIVACY_INSTANCE "unlock(bytes16)" 0x300fbf4b66e2c895415881cde0d9fbb2 --private-key $PRIV_KEY