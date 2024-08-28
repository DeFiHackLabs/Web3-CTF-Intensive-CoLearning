---
timezone: Asia/Shanghai
---

# kkontheway

1. 自我介绍
   Hi, I'm kkontheway.I am currently working as a Cloud security engineer. I am interested in learning about the Web3 Security.
2. 你认为你会完成本次残酷学习吗？
    I will try my best to complete the cruel learning.

## Notes

<!-- Content_START -->

### 2024.08.26

A: Damn Vulnerable DeFi V4(1/18)
---



B:EthTaipei CTF 2023(1/5)
---

**1. Casino**

**Goal**

```solidity
require(IERC20(wNative).balanceOf(address(casino)) == 0);
```
**Solution**

合约模拟了一个老虎机的运行，玩家扮演赌徒，初始状态下玩家有1个`wNative Token`，而赌场有`1000`个，目标就是清空赌场手里的`1000`个`wNative`代币。

有了目标，我们就可以来看一下代码是如何实现的赌场逻辑的:

<details>

```solidity
function play(address token, uint256 amount) public checkPlay {
        _bet(token, amount);
        CasinoToken cToken = isCToken(token) ? CasinoToken(token) : CasinoToken(_tokenMap[token]);
        // play

        cToken.get(msg.sender, amount * slot());
    }

    function slot() public view returns (uint256) {
        unchecked {
            uint256 answer = uint256(blockhash(block.number - 1)) % 1000;
            uint256[3] memory slots = [(answer / 100) % 10, (answer / 10) % 10, answer % 10];
            if (slots[0] == slots[1] && slots[1] == slots[2]) {
                if (slots[0] == 7) {
                    return 100;
                } else {
                    return 10;
                }
            } else if (slots[0] == slots[1] || slots[1] == slots[2] || slots[0] == slots[2]) {
                return 3;
            } else {
                return 0;
            }
        }
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

</details>

玩家首先调用`play()`函数参加赌博，`play()`会调用`_bet()`通过`burn`玩家输入的`token`(我们可以想象成筹码)来实现下注的操作，随后调用`slot()`函数(也就是开始摇动老虎机)，老虎机的判断逻辑是，首先通过`block.number`获取一个随机数(伪随机)，如果三个数字都是`7`那么会翻`100` 倍，但是如果是`7`之外的数字，比如出来的是`666，555，444`只会翻十倍，两个数字一样翻三倍，其余的结果翻两倍。

其实看到这里我就判断解决这道题目的关键就是`block.number`，因为伪随机数漏洞有点太明显，可以通过观看[PatrickAlphaC的视频课程](https://youtu.be/pUWmJ86X_do?t=23418)进一步的了解`Weak Randomnes`。简单来说在区块链中不存在真正意义上的随机数，因为链上的一切都是公开的，题目中使用的`blocknumber`也是一个可被预测和计算的数字，所以我们能够通过计算`block.number`来得知我们在哪一个`block`进行下注能够一定得到`777`的最好结果。

现在我们找到了一条能够让我们赌注翻一百倍的方式！但是我们的初识赌注只有`1 wNative`，就算计算出一次`777`，翻一百倍我们也只能获取到100个`token`，但是我们的目标有整整`1000`个！我们得想想办法。

后面我把目光放在了`_bet()`函数中:
<details>

```solidity
function _bet(address token, uint256 amount) internal {
				//检查是否是允许的underlying Token
        require(isAllowed(token), "Token not allowed");
       
        CasinoToken cToken = CasinoToken(token);
        //如果直接调用失败（可能是因为token是原始代币而不是CasinoToken），则：从_tokenMap获取对应的CasinoToken地址调用deposit函数将原始代币转换为CasinoToken然后再调用CasinoToken的bet函数
        try cToken.bet(msg.sender, amount) {}
        catch {
            cToken = CasinoToken(_tokenMap[token]);
            deposit(token, amount);
            cToken.bet(msg.sender, amount);
        }
    }
```
</details>

起初我在这里没有看到问题，但是后面我把目光放在了`underlying token`的实现中:

<details>

```solidity
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
</details>

`try…catch` 的作用是如果报错那么执行`catch{}`中的内容，但是如果不返回报错呢？

我们可以看到在`wNative`的实现中有一个`fallback()`函数，`fallback`会在调用合约不存在的函数时触发，详细内容可以查看[WTF的文章](https://www.wtf.academy/docs/solidity-102/Fallback/)，这下我们的解题思路就明确了。

1. 调用`play()`函数，传入`wNative token`和大于0的`amount`，这里我们可以传入一个500
2. 然后使用循环也好或者爆破也可以，找到一个返回非0的`block.number`
3. 最后直接调用`withdraw`即可直接取出所有的`wNative`
4. 后面发现也不需要管`block.number`，直接在调用play的时候传入一个足够大的数字，什么`5k`，`1w`的都可以，然后直接`withdraw`就可以了

## Exp
In WriteUp/kkontheway/

C:MetaTrust 2023 (22)
---


<!-- Content_END -->
