The core idea is to use callback mechanism of onERC721Received, which can make the attacker contract take over the control flow to call the NFT minting function again.

Specifically, the onERC721Received function can call claim function with a assigned times before the state being changed to stop the mint.
