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
