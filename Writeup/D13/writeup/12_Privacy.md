# 12 - Privacy

## 題目
[Privacy](https://ethernaut.openzeppelin.com/level/0x131c3249e115491E83De375171767Af07906eA36)

### 通關條件
1. 這個合約的開發者非常小心的保護了 storage 敏感資料的區域. 把這個合約解鎖就可以通關喔！

### 提示
1. 理解 storage 是如何運作的
2. 理解 parameter parsing 的原理
3. 理解 casting 的原理

## 筆記

1. storage的概念在 [08 Vault 的 writeup](./08_Vault.md) 有提到了
2. parameter parsing 是指 EVM 會依據 ABI 解碼規範自動將數據使用對應的型態，這邊我不確定我的理解對不對，如果有更好的說法或是更詳細的解釋歡迎跟我分享
3. casting 的部分可以參考這篇 [Learn Solidity lesson 22. Type casting.](https://medium.com/coinmonks/learn-solidity-lesson-22-type-casting-656d164b9991)
- 底下是這個合約儲存的變數，只要將他按照storage slot的方式排序，就可以知道我們要找的`data[2]`在哪個位置
``` solidity
bool public locked = true;
uint256 public ID = block.timestamp;
uint8 private flattening = 10;
uint8 private denomination = 255;
uint16 private awkwardness = uint16(block.timestamp);
bytes32[3] private data;
```
| slot  | (type)Variable |
|  ----  | ----  |
| slot 0 | (bool)locked |
| slot 1 | (uint256)ID |
| slot 2 | (uint8)flattening, (uint8)denomination, (uint16)awkwardness |
| slot 3 | (bytes32)data[0] |
| slot 4 | (bytes32)data[1] |
| slot 5 | (bytes32)data[2] |

所以我們要的`data[2]`在 slot 5