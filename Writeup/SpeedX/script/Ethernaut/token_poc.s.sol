import "forge-std/Script.sol";
import "Ethernaut/token_poc.sol";
import "forge-std/console.sol";

contract TokenPOCScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TokenPOC tokenPOC = TokenPOC(0x820a8F256D783c5d4bC5c66E8557Ce3929ABce2D);
        tokenPOC.exploit();

        vm.stopBroadcast();
    }
}