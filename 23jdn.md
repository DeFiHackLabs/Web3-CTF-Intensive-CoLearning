---
timezone: Asia/Shanghai
---
---

# {23jdn}

1. 自我介绍: 传统安全人员，为踏入web3安全做准备
2. 你认为你会完成本次残酷学习吗？：尽量完成

## Notes

<!-- Content_START -->

### 2024.08.29

今日概况:
之前实操时一般习惯在remix VM或Truffle上进行题目合约代码的部署以及后续的交互，与Foundry的交互比较少，今天大部分时间了解环境的部署与后续的题目选择。

#### Foundry curl(7)错误
Foundry安装方法比较简单，但由于其他因素可能会导致一些问题，目前遇到的问题为网络环境问题被墙导致执行curl -L https://foundry.paradigm.xyz | bash 出现curl(7)的错误，本想着通过docker pull部署，但由于网络被墙的问题以及ubuntu下无法配置全局网络代理导致docker pull失败，后面了解到curl(7)该错误由于使用的节点与“raw.githubusercontent.com”网站出现dns解析异常而导致失败，通过https://www.ipaddress.com 查询对应域名dns解析Ip 添加对应ip到系统文件hosts处实现强制指向从而解决curl(7)错误



<!-- Content_END -->
