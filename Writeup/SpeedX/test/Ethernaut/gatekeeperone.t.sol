pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import {GatekeeperOne} from "Ethernaut/gatekeeperone.sol";
import {GatekeeperOnePoc} from "Ethernaut/gatekeeperone_poc.sol";

import "forge-std/console.sol";

contract GatekeeperOneTest is Test {
    GatekeeperOne gatekeeperOne;
    GatekeeperOnePoc gatekeeperOnePoc;

    function setUp() public {
        gatekeeperOne = new GatekeeperOne();
        gatekeeperOnePoc = new GatekeeperOnePoc(address(gatekeeperOne));
    }
    // 将 uint160 转为十六进制字符串
    function uint160ToHexString(uint160 value) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes20 data = bytes20(value);  // 将 uint160 转换为 bytes20
        bytes memory str = new bytes(42); // 2 characters for '0x' and 40 characters for the hex representation
        
        str[0] = '0';
        str[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];  // 高4位
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))]; // 低4位
        }
        
        return string(str);
    }

    function uint16ToHexString(uint16 value) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes2 data = bytes2(value);  // 将 uint16 转换为 bytes2
        bytes memory str = new bytes(6); // 2 characters for '0x' and 4 characters for the hex representation
        
        str[0] = '0';
        str[1] = 'x';

        for (uint i = 0; i < 2; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];  // 高4位
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))]; // 低4位
        }
        
        return string(str);
    }

    function testExploit() public {
      bytes8 _gateKey = bytes8(0x00000001_00001f38);

    //   console.log("tx.origin", tx.origin);
    //   console.log("_gateKey", uint64(_gateKey));
    //   console.log("uint160(tx.origin)", uint16ToHexString(uint16(uint160(tx.origin))));
    //   console.log(uint16(uint160(tx.origin))); //target
    //   console.log(uint32(uint64(_gateKey)));
    //   console.log(uint64(_gateKey));

      gatekeeperOnePoc.exploit(_gateKey);

      assertEq(gatekeeperOne.entrant(), tx.origin);


    //   for (uint i = 0; i < 100000; i++) {
    //     try gatekeeperOnePoc.exploit{gas: 8191 + 22120}(_gateKey) {
    //         console.log("exploit success", i);
    //         break;
    //     } catch {
    //         console.log("exploit failed", i);
    //     }
    //   }
    }
}