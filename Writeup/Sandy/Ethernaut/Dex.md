# Dex

```
    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }
```

* 初始

| User | Amount | 
| -------- | -------- |
| A | 10     | 
| B    | 10     |

| Dex | Amount | 
| -------- | -------- |
| A | 100     | 
| B    | 100     |

10 x 100/1000 =10
* userA-10
* UserB+10
* DexA+10
* DexB-10

---
* 第一次交換

| User | Amount | 
| -------- | -------- |
| A | 0     | 
| B    | 20     |

| Dex | Amount | 
| -------- | -------- |
| A | 110     | 
| B    | 90     |

20 x 110/90 = 24......

* userA+24
* UserB-20
* DexA-24
* DexB+20


---

* 第二次交換

| User | Amount | 
| -------- | -------- |
| A | 24     | 
| B    | 0     |

| Dex | Amount | 
| -------- | -------- |
| A | 86     | 
| B    | 110     |

---

* 第三次交換

| User | Amount | 
| -------- | -------- |
| A | 0     | 
| B    | 30     |

| Dex | Amount | 
| -------- | -------- |
| A | 110     | 
| B    | 80     |

---

* 第四次交換

| User | Amount | 
| -------- | -------- |
| A | 41     | 
| B    | 0     |

| Dex | Amount | 
| -------- | -------- |
| A | 69     | 
| B    | 110     |

---

* 第五次交換

|User | Amount | 
| -------- | -------- |
| A | 0     | 
| B    | 65     |

| Dex | Amount | 
| -------- | -------- |
| A | 110     | 
| B    | 45     |

41 x 110/69 =65....
UserA-41
UserB+65
DexA+41
DexB-65

---

* 第六次交換

User2 手上 tokenB 數量超過 Dex 池子所持有的 tokenB 數量 ->transfer amount exceeds balance
