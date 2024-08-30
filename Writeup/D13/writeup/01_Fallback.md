
# 1 - Fallback writeup
## 題目
[Fallback](https://ethernaut.openzeppelin.com/level/0x3c34A342b2aF5e885FcaA3800dB5B205fEfa3ffB)
### 通關條件
1. 獲得這個合約的所有權
2. 把合約的餘額歸零
### 提示
1. 如何透過與 ABI 互動發送 ether
2. 如何在 ABI 之外發送 ether
3. 轉換 wei/ether 單位（參見 help（）指令）
4. fallback 方法


## 提示筆記


### 1. 如何透過與 ABI 互動發送 ether？
只能發送加密貨幣給帶有`payable`的function。當你呼叫他並打算把錢轉過去時，ether, gas必須使用`{}`傳，如下列出表示想呼叫`exampleContract`的`test`時會給合約1 ether：

``` Solidity
exampleContract.test{value: 1 ether}();
```

### 2. 如何在 ABI 之外發送 ether
當你不打算透過合約裡的function發送ether；想直接將ether發送至特定地址時，就需要透過這三個function進行轉帳，建議都使用`call()`：
  1. `transfer`: 安全且簡單，如果失敗會自動回滾交易，受限於 2300 gas。
  2. `send`: 不會自動回滾交易，需要手動檢查是否成功，受限於 2300 gas。
  3. `call`: 最靈活的選項，可以指定 gas 和其他參數，但需要手動處理失敗情況。

### 3. 轉換 wei/ether 單位

$ 1 \text{ ether} = 10^9 \text{ gwei} = 10^{18} \text{ wei} $

Solidity 有內建單位，可以換算：

``` Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EtherUnits {
    uint256 public oneWei = 1 wei;
    // 1 wei is equal to 1
    bool public isOneWei = (oneWei == 1);

    uint256 public oneGwei = 1 gwei;
    // 1 gwei is equal to 10^9 wei
    bool public isOneGwei = (oneGwei == 1e9);

    uint256 public oneEther = 1 ether;
    // 1 ether is equal to 10^18 wei
    bool public isOneEther = (oneEther == 1e18);
}
```

### 4. fallback 方法
當有人呼叫合約中不存在的function的時候`fallback()`會被觸發，也可以用於收款。直接向地址轉帳時，地址合約要有`fallback()`或是`receive()`才可以交易成功。

## 解題筆記

``` Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```

1. 這題目標是要成為合約的所有者跟提款，找到30行的`withdraw()`是負責處理提款的function，但有一個modifier要先處理
> [!info]
> modifier
2. modifire會檢查呼叫合約的人是不是owner，所以還是要先成為owner才有辦法提款，尋找可以給owner賦值的地方，在第 22, 36 行
3. 22 行的`owner = msg.sender;`可以將我們變成合約的擁有者，但它的條件太難達成：
    
    1. 21 行檢查資產要 >owner (`contributions[owner] = 1000 ether`，見第10行)
    2. 20 行可以增加資產但被 19 行阻擋每次增加只能 <0.001 ether

4. 36 行被包在`receive()`裡面，也就是說只要往地址轉錢就可以觸發，但是還有一個條件是`contributions[msg.sender] > 0`也就是我們的地址要先有錢再裡面才行
5. 攻擊思路：透過`contribute()`轉一點錢進去，再往地址轉帳觸發`receive()`，順利接管合約，呼叫`withdraw()`將合約中的餘額全數領走