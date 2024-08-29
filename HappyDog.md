---
timezone: Pacific/Auckland
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
  

<!-- Content_END -->
