
- 目標：找到一組 hash 可以通過 ConfidentialHash 的 `checkthehash()` 檢查，取得 `True` 返回值

- 方法：ConfidentialHash 合約中透過 `ALICE_PRIVATE_KEY`, `ALICE_DATA` 兩個變數組成 `aliceHash`，以及 `BOB_PRIVATE_KEY`, `BOB_DATA` 兩個變數組成 `bobHash`，雖然變數宣告成 private variable，但如果知道他在合約中的 storage slot layout 是怎麼儲存這些變數的話，就可以利用 `vm.load()` 方法取出指定的 storage slot，因此需要了解 string, uint, bytes 的儲存規則，便可取得必要的變數計算出正確 hash，通過 `checkthehash()` 的檢查

- 步驟：``forge test --match-contract ConfidentialHashTest -vvvvv``，前置作業先計算出 `ALICE_PRIVATE_KEY`, `ALICE_DATA`, `BOB_PRIVATE_KEY`, `BOB_DATA` 這四個變數的 slot 位置，分別位於 slot2, slot3, slot7, slot8，進而計算出 `aliceHash`, `bobHash` 這兩個 hash 值。接著執行 expolit 前先確認 `confidentialHash.checkthehash()` 會如預期revert，再利用 `aliceHash`, `bobHash` 這兩個 hash 值做為參數呼叫 `confidentialHash.hash()`，最後再呼叫 `confidentialHash.checkthehash()` 完成取得 `True` 返回值的目標
