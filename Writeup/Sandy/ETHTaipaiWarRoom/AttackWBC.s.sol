// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {WBC, WBCBase} from "../src/WBC/WBC.sol";
contract AttackWBC{
    WBC public wbc;
    WBCBase public base;
    Ans public ans;

    function testSalt1(uint256 a, uint256 b, address wbcAddress) public view returns(uint256){
        uint256 salt;
        for (uint256 i = a; i < b; ++i) {
            address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                i,
                keccak256(abi.encodePacked(
                    type(Ans).creationCode,
                    abi.encode(wbcAddress)
                ))
            )))));
            if (uint256(uint160(predictedAddress)) % 100 == 10){
                console.log("salt: %s", i);
                console.log("predictedAddress %s", predictedAddress);
                salt = i;
                break;
            }
        }
        return salt;
    }

    function testSalt2(address wbcAddr) external {
        uint256 salt;

        for (uint256 i = 0; i < 1000; ++i) {
            try new Ans{salt: bytes32(i)}(wbcAddr) returns (Ans) {
                salt = i;
                console.log(salt);
                break;
            } catch {}
        }
    }

    function testExploit() public returns(address) {
        base = new WBCBase();
        base.setup();
        wbc = base.wbc();
        console.log(address(wbc));
        uint256 salt = testSalt1(0, 200, address(wbc));
        ans = new Ans{salt: bytes32(salt)}(address(wbc));
        ans.win();
        return address(ans);
    }
}

contract Ans {
    WBC public wbc;

    constructor(address wbc_) {
        wbc = WBC(wbc_);
        wbc.bodyCheck();
    }

    function win() external {
        wbc.ready();
    }

    function judge() external view returns (address) {
        return block.coinbase;
    }

    function steal() external pure returns (uint160) {
        return 507778882907781185490817896798523593512684789769;
    }

    function execute() external pure returns (bytes32) {
        //string memory ans = "HitAndRun";
        return bytes32(uint256(uint80(bytes10(0x09486974416e6452756e))));
        
    }

    function shout() external view returns (bytes memory) {
        if (gasleft() >= 93393070) { // 這裡不確定是不是有更好的寫法
            console.logString("I'm the best");
            //return abi.encode(bytes(abi.encodePacked("I'm the best")));
            return "I'm the best";
        } else {
            console.logString("We are the champion!");
            //return abi.encode(bytes(abi.encodePacked("We are the champion!")));
            return "We are the champion!";
        }
    }
}
