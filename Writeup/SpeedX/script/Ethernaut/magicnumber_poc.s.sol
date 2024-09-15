pragma solidity ^0.8.24;

import "Ethernaut/magicnumber_poc.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


interface Solver {
    function whatIsTheMeaningOfLife() external view returns (bytes32);
}

contract MagicNumberPocScript is Script
{
  function run() external 
  {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerKey);

    MagicNumberPoc mnp = MagicNumberPoc(0x72721C3a53F84562707a0E13de3aB5C85b3Da826);

    mnp.exploit();

    // address solver1 = 0x66fCc88FB86e0E29A410875c821fA8B4c2bd2246;
    // address solver2 = 0xB75d5d18339730F7297D64B26aAa82148404cC1d;

    // if (validateMagicNum(solver1) == 0x000000000000000000000000000000000000000000000000000000000000002a) {
    //   console.log("solver equal");
    // } else {
    //   console.log("not equal");
    // }

    // console.log("solver1 code size", getCodeSize(solver1));
    // console.log("solver2 code size", getCodeSize(solver2));
    // (bool success, bytes memory result) = solver.staticcall("");

    // uint256 r = abi.decode(result, (uint256));
    // console.log(r);


    vm.stopBroadcast();
  }

  function validateMagicNum(address _solver) private returns(bytes32)
  {
      Solver solver = Solver(_solver);
        // Query the solver for the magic number.
      bytes32 magic = solver.whatIsTheMeaningOfLife();

      return magic;
  }

  function getCodeSize(address _solver) private returns(uint256)
  {
    uint256 size;
    assembly {
        size := extcodesize(_solver)
    }
    return size;
  }
}

