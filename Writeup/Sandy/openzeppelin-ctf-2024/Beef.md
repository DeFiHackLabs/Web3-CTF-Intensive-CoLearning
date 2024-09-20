# Beef

這題不算是做完的
是找解答的
但還是做一下筆記
沒去想到要用“類似”暴力破解的方式
不是從合約找漏洞
要把題目給的地址的持有token burn
totalSupply為0
需要用地址反推公鑰然後破解出私鑰
把地址上的token燒掉
題目提供了這些方法幫助破解
Once we have the public keys, we can assume that the addresses were generated with [Profanity](https://github.com/johguse/profanity) and they are hence vulnerable to brute force.

To get the private keys, you can use already existing implementations or create your own one. Some examples of existing implementations are:

[profanity-brute-force](https://github.com/rebryk/profanity-brute-force)
[nutcracker](https://github.com/DenrianWeiss/nutcracker)

使用以上工具之後 就可以暴力破解此題，把這兩個地址上的token燒掉即可
