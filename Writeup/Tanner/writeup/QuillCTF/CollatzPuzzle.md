
- 目標：讓 attacker 可以成功呼叫目標合約的 `ctf()`

- 方法：由於有限制合約大小需要介於 size > 0 && size <= 32，因此不能像平常一樣用 solidity 撰寫合約，而需要直接部署 evm opcodes 才能最小化合約大小。分成兩部分進行，第一個部分是處理 runtime code，也就是把 `collatzIteration()` 計算 q 的邏輯，第二部分則是處理 initialization code。

- 步驟：``forge test --match-contract CollatzPuzzleTest -vvvvv`` WIP，尚未通過合約大小檢查
