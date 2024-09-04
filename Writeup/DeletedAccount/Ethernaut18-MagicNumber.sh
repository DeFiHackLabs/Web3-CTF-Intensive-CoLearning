#!/bin/bash
runtime_bytecode=`huffc Ethernaut-18-MagicNumber.huff -r`

if [ ${#runtime_bytecode} -gt 20 ]; then
    echo "Runtime Bytecode 超過 10 bytes, 不會通過！"
    exit
fi

echo "正在部署合約, 請稍候..."
creation_bytecode=`huffc Ethernaut-18-MagicNumber.huff -b`
deployed_contract_address=`cast send -r $RPC_OP_SEPOLIA --private-key $PRIV_KEY --create $creation_bytecode | grep contractAddress | tr -s ' ' | cut -d ' ' -f2`
cast send -r $RPC_OP_SEPOLIA $MAGICNUMBER_INSTANCE "setSolver(address)" $deployed_contract_address --private-key $PRIV_KEY