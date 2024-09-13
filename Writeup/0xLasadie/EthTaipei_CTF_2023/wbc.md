# EthTaipei CTF 2023 - WBC
- Scope  
    - WBC.sol  
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

### Impact/Proof of Concept
There are multiple stages that you need to pass, in order to set `scored` as true.
1. To pass `bodyCheck()`, we will need to pass a contract address that will result in 10 after modulus of 100. Hence, we can create a function `testSalt()` to determine what salt to provide to the contract creation that will allow creating an address to fulfill the requirement.
2. The next one is easy, as we need to pass `ready()` which checks  if the block.coinbase is the same as when the WBC contract is created. Hence, we just need to return block.coinbase.
3. The next challenge is to return a value that matches the uint160 value of what's calculated inside `_firstBase()`. Hence, this can be done easily as we just need to replicate the calculation to get the value.
4. The fourth challenge is slightly more complicated, but essentially we just need to typecast/encode/decode "HitAndRun" in multiple layers inside `execute()` and return the value
5. Lastly, we need to implement `shout()` function that returns "I'm the best" first then "We are the champion!". We cannot use a simple variable change to determine which to return, as the staticcall would revert. Hence, we make use of the gasleft() value to determine which result should be returned, and the value can be manually tested first to get it.

```diff
contract Ans {
    WBC public immutable wbc;
    bool called = false;

    constructor(address wbc_) {
        wbc = WBC(wbc_);
        wbc.bodyCheck();
    }

    function win() external {
        wbc.ready();
    }

    function judge() external view returns (address) {
        return block.coinbase;
    }

    function steal() external pure returns (uint160) {
        return 507778882907781185490817896798523593512684789769;
    }

    function execute() external pure returns (bytes32) {
        string memory ans = "HitAndRun";
        return bytes32(uint256(uint80(bytes10(abi.encodePacked(uint8(bytes(ans).length), ans)))));
    }

    function shout() external view returns (string memory) {
        
        if (gasleft() >= 8797746687695873955) { // Manually tested to get this value 8797746687695873955
            return "I'm the best";
        } else {
            console.log("gas: ",gasleft());
            return "We are the champion!";
        }
    }
}

function testSalt() external {
        uint256 salt;

        for (uint256 i = 0; i < 1000; ++i) {
            try new Ans{salt: bytes32(i)}(address(wbc)) returns (Ans) {
                salt = i;
                break;
            } catch {}
        }
        console2.log(salt);
    }

    function testExploit() external {
        uint256 salt = 94;
        
        ans = new Ans{salt: bytes32(salt)}(address(wbc));
        ans.win();
        base.solve();
        assertTrue(base.isSolved());
    }
```

Results:
```diff
Ran 2 tests for test/WBC.t.sol:WBCTest
[PASS] testExploit() (gas: 332555)
Logs:
  gas:  8797746687695871866

  
[PASS] testSalt() (gas: 3887224)
Logs:
  94
```
