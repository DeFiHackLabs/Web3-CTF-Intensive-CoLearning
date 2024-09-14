#!/bin/bash
cast call -r $RPC_OP_SEPOLIA $TOKEN_INSTANCE "balanceOf(address)" $MY_EOA_WALLET | cast to-dec # check: 20
cast send -r $RPC_OP_SEPOLIA $TOKEN_INSTANCE "transfer(address,uint256)" 0x0000000000000000000000000000000000001337 $MY_EOA_WALLET --private-key $PRIV_KEY
cast call -r $RPC_OP_SEPOLIA $TOKEN_INSTANCE "balanceOf(address)" $MY_EOA_WALLET | cast to-dec # check: large number