## Hello World

输入 "HelloWorld" 调用 answer 就行。 
``` solidity
contract HelloWorld {
    bytes32 private immutable _answer;

    bool public success;

    constructor() {
        _answer = keccak256(abi.encodePacked("HelloWorld"));
    }

    function answer(string calldata data) external {
        bytes32 hash = keccak256(abi.encodePacked(data));
        if (hash == _answer) {
            success = true;
        }
    }
}
```

POC:
``` solidity
    function testCorrectAnswer() public {
        HelloWorld h = base.helloWorld();
        h.answer("HelloWorld");
        base.solve();
        assertTrue(base.isSolved());
    }
```

