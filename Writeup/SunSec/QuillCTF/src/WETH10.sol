pragma solidity ^0.8.0;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

// The Messi Wrapped Ether
contract WETH10 is ERC20("Messi Wrapped Ether", "WETH10"), ReentrancyGuard {
  receive() external payable {
    deposit();
  }

  function _burnAll() internal {
    _burn(msg.sender, balanceOf(msg.sender));
  }

  function deposit() public payable nonReentrant {
    _mint(msg.sender, msg.value);
  }

  function withdraw(uint256 wad) external nonReentrant {
    Address.sendValue(payable(msg.sender), wad);
    _burn(msg.sender, wad);
  }

  function withdrawAll() external nonReentrant {
    Address.sendValue(payable(msg.sender), balanceOf(msg.sender));
    _burnAll();
  }

  /// @notice Request a flash loan in ETH
  function execute(address receiver, uint256 amount, bytes calldata data) external nonReentrant {
    uint256 prevBalance = address(this).balance;
    Address.functionCallWithValue(receiver, data, amount);

    require(address(this).balance >= prevBalance, "flash loan not returned");
  }
}
