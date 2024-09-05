#!/bin/bash
cast storage -r $RPC_OP_SEPOLIA $MOTORBIKE_INSTANCE 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc # IMPLEMENTATION_SLOT
forge script script/Ethernaut25-Motorbike.s.sol:Solver --broadcast -f $RPC_OP_SEPOLIA