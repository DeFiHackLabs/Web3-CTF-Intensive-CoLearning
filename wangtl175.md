---
timezone: Asia/Shanghai
---
# wangtl175

1. 自我介绍

   wtl 程序员，web3入门玩家，ctf爱好者
2. 你认为你会完成本次残酷学习吗？

   肯定可以

## Notes

<!-- Content_START -->

### 2024.08.29

使用源码构建foundry
```shell
# clone the repository
git clone https://github.com/foundry-rs/foundry.git
cd foundry
# install Forge
cargo install --path ./crates/forge --profile local --force --locked
# install Cast
cargo install --path ./crates/cast --profile local --force --locked
# install Anvil
cargo install --path ./crates/anvil --profile local --force --locked
# install Chisel
cargo install --path ./crates/chisel --profile local --force --locked
```
初始化项目
```shell
forge init ethernaut
```

水龙头，前两个是sepolia，最后一个是holesky
```shell
https://faucets.chain.link/
https://www.alchemy.com/faucets/ethereum-sepolia
https://cloud.google.com/application/web3/faucet/ethereum/holesky
```

<!-- Content_END -->
