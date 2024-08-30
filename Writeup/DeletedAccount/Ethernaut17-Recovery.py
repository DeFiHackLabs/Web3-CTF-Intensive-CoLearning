# pip3 install eth-utils
from eth_utils import to_bytes, keccak

#------------------------------------------------------
SENDER = '0x1B7623ee5F36a9440226cFF6b465cae39Af7Da57'
NONCE = 1
#------------------------------------------------------

b_sender = to_bytes(hexstr=SENDER)
b_nonce = to_bytes(NONCE)

rlp_encoded = b'\xd6\x94' + b_sender + b_nonce
new_contract_address = keccak(rlp_encoded).hex()[-40:]

#------------------------------------------------------

print(f'Sender Address = {SENDER}')
print(f'Sender Nonce = {NONCE}')
print(f'New Contract Address = 0x{new_contract_address}')