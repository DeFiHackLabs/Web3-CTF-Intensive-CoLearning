# Paradigm CTF 2023 - Hello World
- Scope
    - hello-world/Challenge.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings
### Requirements
1. TARGET.balance > STARTING_BALANCE + 13.37 ether;
### Impact/Proof of Concept
```
contract HelloWorldTest is Test {
    Challenge challenge;
    address player = makeAddr("player");
    function setUp() public {
        challenge = new Challenge();
    }

    modifier solved() {
        _;
        assert(challenge.isSolved());   
    }

    function test_exploit() public solved {
        address TARGET = challenge.TARGET();
        console.log("addr: ", TARGET);
        vm.startPrank(player);
        vm.deal(player, 13.38 ether);
        
        // A simple call to transfer more than 13.37 ether over to the TARGET contract
        (bool success,) = TARGET.call{value: 13.38 ether}("");
        require(success);
        console.log("balance: ", TARGET.balance);
    }

}
```
Results
```diff
Ran 1 test for test/hello-world.t.sol:HelloWorldTest
[PASS] test_exploit() (gas: 50294)
Logs:
  addr:  0x00000000219ab540356cBB839Cbe05303d7705Fa
  balance:  13380000000000000000
```
