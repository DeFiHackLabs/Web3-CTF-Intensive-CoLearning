# Challenge - HelloWorld

None

## Objective of CTF

find the "answer"

## Vulnerability Analysis

Obviously, the answer is "HelloWorld!":

```solidity
_answer = keccak256(abi.encodePacked("HelloWorld"));
```

### Attack steps:

1. Call the `answer()` function with "HelloWorld!"

## PoC test case

```solidity
function testExploit() public {
    HelloWorld helloWorld = base.helloWorld();
    helloWorld.answer("HelloWorld");
    base.solve();
    assertTrue(base.isSolved());
}
```

### Test Result

```
Ran 1 test for test/HelloWorld.t.sol:HelloWorldTest
[PASS] testExploit() (gas: 57690)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 8.03ms (1.32ms CPU time)

Ran 1 test suite in 2.26s (8.03ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
