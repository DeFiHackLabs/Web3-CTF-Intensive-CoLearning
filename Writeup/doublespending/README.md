# Tasks of Doublespending

- A: [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)(18)

  - day1
    - UnstoppableVault
      - [`UnstoppableMonitor.onFlashLoan` revert when fee does not equal to 0](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableMonitor.sol#L27-L29)
      - [`UnstoppableVault.flashLoan` will get 0 fee when `block.timestamp < end && _amount < maxFlashLoan(_token)` is `false`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableVault.sol#L64)
      - Finally, the tx will run into [this logic](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/unstoppable/UnstoppableMonitor.sol#L45-L51).
    - NaiveReceiver
      - We can send all weth of `IERC3156FlashBorrower receiver` to `feeReceiver` by calling [flashLoan](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L43C24-L43C54) 10 times
      - Then, we use `Forwrarder` to call `Multicall` with a `withdraw` call.
      - [In this case, `msg.sender` is `Forwarder` and the pool will use the last 20 bytes as the `sender`](https://github.com/theredguild/damn-vulnerable-defi/blob/d22e1075c9687a2feb58438fd37327068d5379c0/src/naive-receiver/NaiveReceiverPool.sol#L87)
      - So, we can append `feeReceiver` to the `withdraw` call to act as `feeReceiver`.

- B: [EthTaipei CTF 2023](https://github.com/dinngo/ETHTaipei-war-room/)(5)

- C: [Openzeppelin CTF 2023](https://github.com/OpenZeppelin/ctf-2024)(9)
