// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin-contracts-08/contracts/token/ERC20/ERC20.sol";
import {Address} from "@openzeppelin-contracts-08/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin-contracts-08/contracts/access/Ownable.sol";

contract WrappedNative is ERC20("Wrapped Native Token", "WNative"), Ownable {
    using Address for address payable;

    fallback() external payable {
        deposit();
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).sendValue(amount);
    }
}
