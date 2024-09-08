### HarryRiddle

**Fallback**

- Description: The `Fallback` contract can be reclaimed ownership by anyone with fallback methods.

```javascript
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
@>      owner = msg.sender;
    }
```

**Fallout**

- Description: Incorrect in the old constructor name brings on reclaiming ownership.

```javascript
@>  function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

- Proof of Code: As the `Fallout` contract is lower than `0.8.0, i can not implement test in there. Just call `Fallout::Fal1out()` function to reclaim the ownership contract.

**Coin Flip**

- Description: `CoinFlip` contract use the random side of coin by `block.number`.

- Recommended: Using VRF instead.

**Telephone**

- Description: `tx.origin` and `msg.sender` should be different if we use the other contract to call `Telephone` contract.

**Token**

- Description: Underflow / Overflow in version under `0.8.0`.

- Recommended: Using `^0.8.0` version or `Safe Math` library.

**Delegation**

- Description: Careful of using delegate call.

**Force**

- Description: `Force` contract does not have any fallback or receive methods to receive ether. We can force this contract to receive ether by using other contract to destruct itself:

**Vault**

- Description: This `Vault::password` is private so we can not read it. However, everything in blockchain is public, we will get it from storage of `Vault` contract.

- Proof of Code: There are 2 variable with `bool` and `bytes32` type storing at slot 0 and slot 1 in contract's memory because `bool` type is 32 bytes in slot 0 and `bytes32` is in slot 1 (each slot has 32 bytes itself).

```javascript
    bool public locked;
    bytes32 private password;
```

**King**

- Description: `King` contract is competitive contract with the `king` will be the last sending the biggest ether or be sent by `owner`. When other would be the `king`, they will send ether to this contract larger or equal the last `prize` and `King` contract will send back last `king` their ether. What happen if last `king` is a contract without fallback or receive methods? The last `king` will be the king forever.

**Re-entrancy**

- Description: This `Reentrance` contract allows us to re-enter the `withdraw` function through other contract has receive or fallback methods containing `Reentrance::withdraw` call because the `Reentrance::donate` will send ether to the callee. The reason is that the `Reentrance` contract change the user's balance state after the invoker finished.

**Elevator**

- Description: Attack the `Elevator` contract by implementing the other contract with custom `isLastFloor` function.

**Privacy**

- Description:

**Gatekeeper One**

- Description:

```javascript
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }
```

The way to break `gateOne` modifier is that using the other contract to call the function in `GatekeeperOne`

```javascript
    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }
```

We will use `call` methods to call function with `gas` property. The value of gas should be the number of dividable 8191, then i will use loop for applying gas value.

```javascript
    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }
```

```javascript
    uint64 k = uint64(_gateKey);
    => uint32(k) == uint16(k)
    => uint32(k) != uint64(_gateKey)
    => uint32(k) == uint16(uint160(tx.origin))

    // uint32(k) == uint16(uint160(tx.origin))
    // uint32(k) == uint16(k)
    => uint16(k) = uint16(uint160(tx.origin))
    => k = uint160(tx.origin)

    // uint32(k) != uint64(_gateKey)

    => uint64 k64 = uint64(1 << 63) + uint64(k16)
```

**Gatekeeper Two**

- Description:

```javascript
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }
```

The way to break `gateOne` modifier is that using the other contract to call the function in `GatekeeperOne`

```javascript
    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }
```

This code is implied that the contract sender does not have any code. Therefore, we will use only `constructor`

```javascript
    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }
```

**Naught Coin**

- Description: This token implement `ERC20` standard of `Openzeppelin` and override the `transfer` function to apply the duration of time. However, they do not override the `transferFrom` function with the same functionality with `transfer`.

**Preservation**

- Description: `Preservation` contract use the `delegatecall` to call the libraries to set its `storedTime`. To use the `delegatecall` the storage of callee must be match with the storage of caller. The position of `storedTime` in `LibraryContract` is `slot0` but in `Preservation` is `slot4`, then `storedTime` in `LibraryContract` matched with `timeZone1Library` in `Preservation`

```javascript
    contract Preservation {
        // public library contracts
@>      address public timeZone1Library;
        address public timeZone2Library;
        address public owner;
@>      uint256 storedTime;
        .
        .
        .
    }

    contract LibraryContract {
        // stores a timestamp
@>      uint256 storedTime;
        ...
    }
```

**Recovery**

- Description: `Recovery` contract is a factory contract to produce `SimpleToken` with corresponding inputs. We cannot know the new `SimpleToken` contract address when finished because of not code factory verification but we can compute the created contract address based on `sender` and `nonce` (which is the number of address created`).

- Refer: [How is the address of an Ethereum contract computed ?](https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed)

**Magic Number**

- Description:

**Alien Codex**

- Description: The entire storage area is `2^256` and the array will expand to entire storage by the arithmetic underflow of array length. Using `retract` to expand the array to occupy entire storage and change the value of `slot0` by `revise` function to modify the `owner` value stored in `slot0`.

```javascript
    contract AlienCodex is Ownable {
        bool public contact;
@>      bytes32[] public codex;
        ...
        function retract() public contacted {
            codex.length--;
        }

        function revise(uint256 i, bytes32 _content) public contacted {
            codex[i] = _content;
        }
    }
```

**Denial**

- Description: In the `withdraw` function, the `partner` and `owner` will be transfer ether from contract. However, `partner` is withdrawal with `call` methods and `owner` is used by `transfer`. We can prevent the anyone calling the `withdraw` function by using all the gas limit in withdrawal transaction. To do this, we implement the `partner` is the receivable contract having `receive` fallback consume all gas limits.

**Shop**

- Description: The `Shop` contract is dependent on the `price` function of `msg.sender`. So we just make other contract having `price` function return the value based on `Shop::isSold` variable

**DEX**

- Description: The `Dex` contract has `swap` function with the price calculated by `amountOfSwap` and `balance` of token1 of contract and `balance` of token2 of contract. The ratio is 1:1. However, there is rounding issue in division, the ratio after swapping is not 1:1 as initially

```javascript
    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }
```

**DexTwo**

- Description: The `swap` function does not have any check the `from` and `to` token address, the malicious user can pass their virus token address to `from` and `to` address to exploit the contract.

```javascript
    function swap(address from, address to, uint256 amount) public {
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }
```

**DoubleEntryPoint**

- Description:
