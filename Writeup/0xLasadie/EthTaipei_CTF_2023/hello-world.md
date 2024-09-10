# EthTaipei CTF 2023 - Hello World
- Scope
    - HelloWorld.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Answer is explicitly provided in the contract constructor

### Summary
Answer (HelloWorld) is explicitly provided in the constructor, allowing attackers to easily answer with the correct answer.

### Vulnerability Details
The answer is explicitly provided in the constructor.
```diff
constructor() {
-        _answer = keccak256(abi.encodePacked("HelloWorld"));
    }
```

### Impact/Proof of Concept
```
function testCorrectAnswer() public {
        HelloWorld h = base.helloWorld();
        h.answer("HelloWorld");
        console.log("success: ",h.success());
        base.solve();
        assertTrue(base.isSolved());
    }
```

### Recommendations
```
[PASS] testCorrectAnswer() (gas: 61543)
Logs:
  success:  true
```
