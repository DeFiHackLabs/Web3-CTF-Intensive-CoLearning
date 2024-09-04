---
timezone: Asia/Taipei
---

# {你的名字}

1. 自我介绍
我是隻快樂的小狗:)

3. 你认为你会完成本次残酷学习吗？
努力努力努力

## Notes

<!-- Content_START -->

### 2024.08.29

新手小白決定從Ethernaut CTF開始
今天解第一題hello Ethernaut
1. 下載Meta Mesk的extension，實施註冊
2. 把網路改成測試網路Sepolia

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/7b25146e-4c26-401a-a321-c3587a5afafc/image.png)

3. 在Ethernaut的網頁按F12開啟開發者工具和網頁互動
4. 按照裡面的提示輸入一些可以互動的字句
    `await getBalance(player)`
    `await ethernaut.owner()`
    `help()`
   初步的了解整個合約和操作的方式
5. 由於使用會需要一些測試幣，所以沒事就可以去花點心思找個水管來拿測試幣
不得不說我在這邊吃了好多鱉(っ °Д °;)っ
[google cloud可以免費拿0.05](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)
[這裡](https://sepolia-faucet.pk910.de/)花點時間可以慢慢拿
6. 由於截止目前為止我們都是跟這個遊戲本身的合約在互動，所以為了開始第一次的嘗試，我們要開始一個新案例，點點最下面的開始新實例，metamesk會要你同意一筆交易，稍等一下

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/f06686f9-83e3-4f53-a939-26ae69e25406/image.png)

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/e4903f8d-90af-4684-a228-bb565f8a28fa/image.png)

7. 獲得新實例後一樣能夠用幾個指令跟他互動
    `await contract.info()`
一開始的我以為輸入完就能夠提交這個案例，殊不知…..我是個小丑இ௰இ

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/34855164-b12d-4808-a331-30c98e648691/image.png)

8. 去爬了一些文，了解人家運作的過程後，我才更明白整個互動的模式，總之就開始解謎之旅

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/679e40cf-93a1-44a8-811e-944721a76c97/image.png)

9. 看到需要password，回頭到ABI中查看，發現真的有一個Password的function

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/4b706249-9617-40de-bdc4-cf9954b13e0c/image.png)

    ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/06c9c9fb-4c26-4540-bc10-a895b1605dc1/image.png)

10. 獲得密碼後輸入await contract.authenticate(’ethernaut0’)
     ![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/7774fde7-005d-44d4-addc-66fb8267870a/a02937aa-705f-4849-9dac-667f11b890c2/image.png)

----------------

其實從昨天報名完就開始研究整個運作方式，去多挖了一些SepETH
今日目標本來希望能夠順便把POC也研究完，但沒有成功
明日目標：
  1.Foundry寫POC學習
  2.Solidity深入學習
  3.用POC解2題以上

----------------

Solidity：
  一種高級編程語言，用於編寫和部署在以太坊（Ethereum）區塊鏈上的智能合約。它是以太坊開發的主要語言，設計上類似於 JavaScript 和 C++，使開發者能夠創建去中心化應用（DApps）和各種自動化合約。
  (明日將基本語法補充進來)

### 2024.08.30
不小心感冒了，今日將環境架設完畢，並學習Solidity的基本語法
**合約開發框架 Foundry**
- Foundry是由 Rust 語言所寫，為 Solidity 開發者構建的合約開發框架
- 合約編譯和測試執行速度非常快
- 用 Solidity 撰寫測試，只需要專注在 Solidity 本身
- 相比 Hardhat 測試，多了 Fuzzing 測試
- 安裝Foundry
      參考網頁：
          https://hackmd.io/@Ryan0912/ryA8yUK-2
          https://book.getfoundry.sh/getting-started/installation
    1. 先安裝[Rust](https://www.rust-lang.org/tools/install)
    2. #clone the repository
        git clone https://github.com/foundry-rs/foundry.git
        cd foundry
        #install Forge
        cargo install --path ./crates/forge --profile release --force --locked
        #install Cast
        cargo install --path ./crates/cast --profile release --force --locked
        #install Anvil
        cargo install --path ./crates/anvil --profile release --force --locked
        #install Chisel
        cargo install --path ./crates/chisel --profile release --force --locked
    3. 相關套件都安裝完後可以確認版本
        forge --version
        成功會跳出類似下方訊息
        forge 0.2.0 (98ab45eeb 2024-08-30T09:21:16.144880400Z)
    4. 開始建立新的Foundry專案

### 2024.09.02
** 用Foundry來玩Ethernaut **
- [學習參考網址](https://medium.com/@tanner.dev/ethernaut-x-foundry-%E5%A6%82%E4%BD%95%E9%96%8B%E5%A7%8B%E4%BD%A0%E7%9A%84%E7%AC%AC%E4%B8%80%E5%80%8B%E4%BB%A5%E5%A4%AA%E5%9D%8A-ctf-%E6%8C%91%E6%88%B0-prerequisites-to-get-started-707c7cd10cd2)
- 使用git上大神已將Ethernaut整理進Foundry框架的repo
    git clone https://github.com/tannerang/ethernaut-foundry.git
    .env檔案修改內容
    - repo架構
        ├── README.md
        ├── broadcast
        ├── cache
        ├── challenge-contracts // 題目的合約程式碼
        ├── challenge-info // 題目說明和提示
        ├── foundry.toml
        ├── lib
        ├── out
        ├── script
        │   ├── setup
        │   │   ├── EthernautHelper.sol
        │   │   └── IEthernaut.sol
        │   └── solutions // 解題用的部署合約
        └── src // 解題用的攻擊合約

**My First Foundry x Ethernaut - Fall back**
![image](https://github.com/user-attachments/assets/45bebb5c-b759-415e-8bb9-f5ac75d001b8)
1. 令人興奮的第一題，在前置環境等等都已經設定好後，我開始研究這題的Solidity 合約內容，這算是我第一次看，所以我決定要好好的仔細的理解整體脈絡跟用法，奠定一些基礎(在這次看完後我發現有些基礎是需要去稍微理解一下會更好)
2. 這個合約算較為單純，大致了解運作模式後，針對題目去理解，目標就是"成為owner"以及”用withdraw()來歸零”，參考了大神的sol後，由於我的環境並非unix，所以有部分的設定不太一樣，首先是使用$env:來設定環境變數(但.env還是得設定好)，再來就是在執行的部分，命令必須這樣設定
forge script script/solutions/01-Fallback.s.sol:FallbackSolution --fork-url [https://sepolia.infura.io/v3/](https://sepolia.infura.io/v3/a360f95dad004dc1bf712c848f72913b)MyprojectID
3. 後來就順利編譯完成並broadcast出去

--------------
今日回顧與思考：
1.在撰寫POC的部分，我可能還需要再加強Foundry的理解
2.關於Solidity合約已經有更多的了解了，但若後面要能夠越來越厲害，必須要加強基礎的部分
3.今天的我很棒，成功完成第一次的POC(雖然還是因為有大神在QAQ)
  
<!-- Content_END -->
