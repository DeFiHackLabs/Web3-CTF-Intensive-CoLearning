# coding=utf-8
"""
@Project     : Web3-CTF-Intensive-CoLearning
@Author      : Snooowgh
@File Name   : Recovery
@Description :
@Time        : 2024/9/05 16:29
"""
from web3 import Web3
import os

# Holesky
w3 = Web3(Web3.HTTPProvider("https://holesky.drpc.org"))

private_key = os.getenv('CTF_PRIVATE_KEY')
addr = w3.eth.account.from_key(private_key).address

tx = {
    'nonce': w3.eth.get_transaction_count(addr),
    'value': w3.to_wei(0, 'ether'),
    'gasPrice': w3.eth.gas_price,
    "data": "0x600a600c600039600a6000f3602a60805260206080f3"
}
tx["gas"] = w3.eth.estimate_gas(tx)

signed_tx = w3.eth.account.sign_transaction(tx, private_key)
tx = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
receipt = w3.eth.wait_for_transaction_receipt(tx)
print(receipt)
contractAddress = receipt["contractAddress"]

contract = w3.eth.contract(address=contractAddress, abi=[
    {
        "inputs": [],
        "name": "whatIsTheMeaningOfLife",
        "outputs": [
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
])
ret = contract.functions.whatIsTheMeaningOfLife().call()
print(ret)
print(ret.hex())
target_contract = "0xcc730C9702d18f00a0Ac56A5fe945e0df30199E0"

contract_abi = [
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_solver",
                "type": "address"
            }
        ],
        "name": "setSolver",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

contract = w3.eth.contract(address=target_contract, abi=contract_abi)

tx = contract.functions.setSolver(contractAddress).build_transaction({
    'from': addr,
    'nonce': w3.eth.get_transaction_count(addr),
    "value": 0,
    "gasPrice": w3.eth.gas_price
})
tx["gas"] = w3.eth.estimate_gas(tx)

signed_tx = w3.eth.account.sign_transaction(tx, private_key)
tx = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
receipt = w3.eth.wait_for_transaction_receipt(tx)
print(receipt)
