#!/bin/bash
for i in {0..9}
do
  forge script Ethernaut03-CoinFlip.s.sol:Solver -f $RPC_OP_SEPOLIA --broadcast
done