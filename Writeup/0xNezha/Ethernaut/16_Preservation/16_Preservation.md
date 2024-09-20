### 第16关：Preservation 
这一关主要考察delegatecall()。目标合约想要通过 timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp)) 来调用库合约的 setTime(uint256 _time) 达到修改目标合约中 uint256 storedTime 变量的目的。然而使用 delegatecall() 函数进行外部调用时，当涉及到 storage 变量的修改时，是根据 slot 的位置来修改的，而不是通过变量名。也就是说库合约中的 uint256 storedTime 位于 slot0，则目标合约调用外部函数时，修改的也是目标合约的 slot0 （也就是 address public timeZone1Library ），而不是位于其他 slot 的变量 storedTime。

1. 我们先部署一个攻击合约 X （它可以修改 slot3），然后调用 setFirstTime(uint256 _timeStamp) *(当然，setSecondTime(uint256 _timeStamp) 也可以)* , 传入合约 X 的地址，把 timeZone1 的地址覆盖为了合约 X 的地址。
2. 继续调用  setFirstTime(uint256 _timeStamp) ，这时执行的是我们攻击合约的函数，把 _timeStamp 设置为攻击合约，_timeStamp 传入攻击者的地址，从而覆盖 Owner.