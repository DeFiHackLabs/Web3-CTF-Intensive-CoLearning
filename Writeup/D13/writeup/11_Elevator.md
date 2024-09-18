# 11 - Elevator

## 題目
[Elevator](https://ethernaut.openzeppelin.com/level/0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2)

### 通關條件
1. 這台電梯會讓你到不了頂樓對吧？

### 提示
1. 有的時候 Solidity 不是很遵守承諾
2. 我們預期這個 Elevator(電梯) 合約會被用在一個 Building(大樓) 合約裡

## 筆記

- 學會當個惡意套件讓人使用就對了 😈
- 實作一個 `isLastFloor()`，而且要能夠每次被呼叫會回傳不同值，這方面很直得自己去想一下，提升對於函數設計的思維。