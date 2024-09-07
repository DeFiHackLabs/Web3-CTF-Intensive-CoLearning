`Engine` 的 `initialize` 是通过 `delegatecall` 调用的，因此 `Engine` 的 `upgrader` 变量并没有真的设置，可以再直接调用  `initialize` 获得 `Engine`  的更新权。

Cancun 升级之后无法彻底 selfdestruct 一个已经部署的合约，因此难以复现。可能的方法是在同一个交易里创建 level 实例并完成攻击。

