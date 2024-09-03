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

解法:

- [Ethernaut22-Dex.sh](/Writeup/DeletedAccount/Ethernaut22-Dex.sh)
- [Ethernaut22-Dex.s.sol](/Writeup/DeletedAccount/Ethernaut22-Dex.s.sol)

<!-- Content_END -->