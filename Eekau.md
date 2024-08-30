---
timezone: Asia/Taipei # 台灣标准时间 (UTC+8)
---


# Eekau

1. 自我介绍
hi, im Eekau.
2. 你认为你会完成本次残酷学习吗？
第一次參加希望能完成

# 殘酷共學

<!-- Content_START -->
- 1.Ethernaut CTF (31)
- 4.Ethcc CTF 2023 (5)
- 13.Openzeppelin CTF 2023 (9)

### 2024.08.29
>##### Ethernaut CTF (1/31)
>>###### Hello Ethernaut
>>1. 建立錢包
>>2. 在[Ethereum Faucet](https://cloud.google.com/application/web3/faucet/ethereum)領取Holešky測試幣 (可以使用其他網路)
>>3. 把網路切到Holešky開始遊戲
>>4. 根據說明在console裡輸入info()
>>5. 根據"PromiseResult"指示輸入ABI最終會需要輸入密碼
>>6. 輸入contract 查找ABI 發現password()這個function 找到密碼
>>7. 輸入獲得密碼 (這邊記得要把字串放在""裡面)
>>8. 點選網頁下方Submit instance
>>9. 獲得成功破關畫面

### 2024.08.30
>#### Ethernaut CTF (2/31)
>>##### Fallback
>> ###### 目標：成為owner，偷光合約的錢
>> ###### 先備知識 
>> - 了解 fallback
>> - 知道如何 sendTransaction
>> ###### 解題
>> 1. 觀察程式碼發現能更改owner的地方，除了`constructor()` 外有兩處 `contribute()` 和 `receive()`
>>```solidity
>>function contribute() public payable {
>>     require(msg.value < 0.001 ether); //只要發送0.001以上的ether
>>     contributions[msg.sender] += msg.value;// 發送者獲得ether貢獻
>>     if (contributions[msg.sender] > contributions[owner]) {
>>     //只要發送者交給合約的ether比owner多
>>         owner = msg.sender; //把owner更換為發送者
>>     }
>> }
>> ```
>> 然而constructor()時 已經預設`contributions[msg.sender] = 1000 * (1 ether)` 自己的錢包並沒有這樣龐大數目的eth
>>```solidity
>>receive() external payable {
>>      require(msg.value > 0 && contributions[msg.sender] > 0);
>>      //只要msg.value大於0且有貢獻
>>      owner = msg.sender;
>>  }
>> ```
>> `receive()`觸發條件為 發送ether+msg.data為空。
>> 2. 使用`await contract.contribute.sendTransaction({ from: player, value: toWei('0.0009')})` 讓contributions不為0
>> 3. 試著觸發receive...（卡關...）

### 2024.08.31



### 2024.09.1



<!-- Content_END -->
