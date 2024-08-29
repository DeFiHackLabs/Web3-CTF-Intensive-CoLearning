#!/bin/bash
cast balance $FORCE_INSTANCE -r $RPC_OP_SEPOLIA # should be 0
forge script Ethernaut07-Force.s.sol:Solver -f $RPC_OP_SEPOLIA --broadcast
cast balance $FORCE_INSTANCE -r $RPC_OP_SEPOLIA # should be 1
