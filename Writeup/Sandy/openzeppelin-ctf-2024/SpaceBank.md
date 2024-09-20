**SpaceBank**

* EmergencyAlarms++有三關
    * 第一關 EmergencyAlarms == 1，要在同一個block.number完成
    * 第二關EmergencyAlarms == 2
        * ```  
            assembly {
                newContractAddress := create2(0, add(data, 0x20), mload(data), MagicNumber)
            }
    之後address(this).balance 會增加

    * alarmTime = block.number
    * 第三關EmergencyAlarms == 3
        * 不能走到第三遍，會revert     
* IFlashLoanReceiver 沒有定義內容
* `function explodeSpaceBank()`
    * block.number == alarmTime + 2(需要在第二關EmergencyAlarms後兩塊)
    * 此時的`_createdAddress` codesize 為零可見合約已經消失了
    * 合約上的token 也要歸零 -> 要全部領完

* 有`modifier _emergencyAlarms(bytes calldata data)`的才會進到_emergencyAlarmProtocol過三關
    * -> 只有deposit 會用到此modifier會用到 -> 所以需要deposit 2次
    * -> 第一次deposit的data必須等於block.number％47
    * -> 第二次deposit 為了要過第二關EmergencyAlarms == 2，必須用create2創一個合約，創完合約之後，balance要增加，可以得知是要做一個selfdestruct合約，data為合約的creation code，並且在建立合約時要帶value，由於是由SpaceBank呼叫製作合約，因此合約自毀之後，value會送回SpaceBank，便可以達成balance增加
    * -> 記下alarmTime，把銀行搞爆必須要在這個alarmTime+2個block之後
    * 又，一定要經過deposit這個步驟而且要兩次，考量順序問題，deposit()必須在flashLoan()
    * 之中，的`flashLoanReceiver.call(abi.encodeWithSignature("executeFlashLoan(uint256)", amount));`尚未定義的function 中執行才能滿足兩次deposit 的條件，因此flashLoan()做完之後，要把deposit 的再領出來
    * 然後呼叫explodeSpaceBank()
