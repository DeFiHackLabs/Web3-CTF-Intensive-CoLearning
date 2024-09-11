pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/26-DoubleEntryPoint/DoubleEntryPoint.sol";
import "../../src/ethernaut/26-DoubleEntryPoint/DoubleEntryPointFactory.sol";

contract DetectionBot is IDetectionBot {
    address immutable cryptoVault;

    constructor(address _cryptoVault) {
        cryptoVault = _cryptoVault;
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        // skip the first 4 bytes, because it's a function signatures
        (,, address originSender) = abi.decode(msgData[4:], (address, uint256, address));

        // prevent anyone from transferring the underlying token out of the vault
        if (originSender == cryptoVault) {
            IForta(msg.sender).raiseAlert(user);
        }
    }
}

contract DoubleEntryPointTest is Test {
    Ethernaut ethernaut;
    DoubleEntryPoint point;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }


    function testAttck() public {
        DoubleEntryPointFactory factory = new DoubleEntryPointFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);

        point = DoubleEntryPoint(levelAddress);

        Forta forta = Forta(point.forta());
        DetectionBot detectionBot = new DetectionBot(address(point.cryptoVault()));
        forta.setDetectionBot(address(detectionBot));

        CryptoVault vault = CryptoVault(point.cryptoVault());
        console.log("before sweep");
        console.log("LGT",IERC20(point.delegatedFrom()).balanceOf(address(vault)));
        console.log("DET",IERC20(point).balanceOf(address(vault)));

        try vault.sweepToken(IERC20(point.delegatedFrom())) {
        } catch {
        }
        console.log("after sweep");
        console.log("LGT",IERC20(point.delegatedFrom()).balanceOf(address(vault)));
        console.log("DET",IERC20(point).balanceOf(address(vault)));
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
