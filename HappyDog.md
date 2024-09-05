---
timezone: Asia/Taipei
---
##HappyDog
1. 我是隻快樂的小狗:)
2. 努力努力努力

## Notes

<!-- Content_START -->

### 2024.08.29

#新手小白決定從Ethernaut CTF開始
今天解第一題hello Ethernaut
1. 下載Meta Mesk的extension，實施註冊
2. 把網路改成測試網路Sepolia
![image](https://github.com/user-attachments/assets/fcc73e9e-2663-416a-b909-a2228c71af05)

3. 在Ethernaut的網頁按F12開啟開發者工具和網頁互動
4. 按照裡面的提示輸入一些可以互動的字句
    `await getBalance(player)`
    `await ethernaut.owner()`
    `help()`
   初步的了解整個合約和操作的方式
5. 由於使用會需要一些測試幣，所以沒事就可以去花點心思找個水管來拿測試幣
不得不說我在這邊吃了好多鱉(っ °Д °;)っ
[google cloud可以免費拿0.05](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)
[這裡](https://sepolia-faucet.pk910.de/)花點時間可以慢慢拿
6. 由於截止目前為止我們都是跟這個遊戲本身的合約在互動，所以為了開始第一次的嘗試，我們要開始一個新案例，點點最下面的開始新實例，metamesk會要你同意一筆交易，稍等一下
![image](https://github.com/user-attachments/assets/b349ace7-4a77-48ab-ac4f-093f57cc105b)
7. 獲得新實例後一樣能夠用幾個指令跟他互動
    `await contract.info()`
一開始的我以為輸入完就能夠提交這個案例，殊不知…..我是個小丑இ௰இ
![image](https://github.com/user-attachments/assets/54d82929-3f59-4a9c-8d2b-98f3f59c1af5)
8. 去爬了一些文，了解人家運作的過程後，我才更明白整個互動的模式，總之就開始解謎之旅
![image](https://github.com/user-attachments/assets/e8972ddd-3c1e-4531-896e-e1e30653257b)
9. 看到需要password，回頭到ABI中查看，發現真的有一個Password的function
![image](https://github.com/user-attachments/assets/6eff278f-aea7-4e94-be25-b48111b83b9a)
10. 獲得密碼後輸入await contract.authenticate(’ethernaut0’)
![image](https://github.com/user-attachments/assets/853e6bf8-27f9-453a-ab1a-77bc12945cbf)

----------------

其實從昨天報名完就開始研究整個運作方式，去多挖了一些SepETH
今日目標本來希望能夠順便把POC也研究完，但沒有成功
明日目標：
  1.Foundry寫POC學習
  2.Solidity深入學習
  3.用POC解2題以上

----------------

### 2024.08.30
不小心感冒了，今日將環境架設完畢，並學習Solidity的基本語法
**合約開發框架 Foundry**
- Foundry是由 Rust 語言所寫，為 Solidity 開發者構建的合約開發框架
- 合約編譯和測試執行速度非常快
- 用 Solidity 撰寫測試，只需要專注在 Solidity 本身
- 相比 Hardhat 測試，多了 Fuzzing 測試
- 安裝Foundry
      參考網頁：
          https://hackmd.io/@Ryan0912/ryA8yUK-2
          https://book.getfoundry.sh/getting-started/installation
    1. 先安裝[Rust](https://www.rust-lang.org/tools/install)
    2. #clone the repository
        git clone https://github.com/foundry-rs/foundry.git
        cd foundry
        #install Forge
        cargo install --path ./crates/forge --profile release --force --locked
        #install Cast
        cargo install --path ./crates/cast --profile release --force --locked
        #install Anvil
        cargo install --path ./crates/anvil --profile release --force --locked
        #install Chisel
        cargo install --path ./crates/chisel --profile release --force --locked
    3. 相關套件都安裝完後可以確認版本
        forge --version
        成功會跳出類似下方訊息
        forge 0.2.0 (98ab45eeb 2024-08-30T09:21:16.144880400Z)
    4. 開始建立新的Foundry專案

### 2024.09.02
** 用Foundry來玩Ethernaut **
- [學習參考網址](https://medium.com/@tanner.dev/ethernaut-x-foundry-%E5%A6%82%E4%BD%95%E9%96%8B%E5%A7%8B%E4%BD%A0%E7%9A%84%E7%AC%AC%E4%B8%80%E5%80%8B%E4%BB%A5%E5%A4%AA%E5%9D%8A-ctf-%E6%8C%91%E6%88%B0-prerequisites-to-get-started-707c7cd10cd2)
- 使用git上大神已將Ethernaut整理進Foundry框架的repo
    git clone https://github.com/tannerang/ethernaut-foundry.git
    .env檔案修改內容
    - repo架構
        ├── README.md
        ├── broadcast
        ├── cache
        ├── challenge-contracts // 題目的合約程式碼
        ├── challenge-info // 題目說明和提示
        ├── foundry.toml
        ├── lib
        ├── out
        ├── script
        │   ├── setup
        │   │   ├── EthernautHelper.sol
        │   │   └── IEthernaut.sol
        │   └── solutions // 解題用的部署合約
        └── src // 解題用的攻擊合約

**My First Foundry x Ethernaut - Fall back**
![image](https://github.com/user-attachments/assets/45bebb5c-b759-415e-8bb9-f5ac75d001b8)
1. 令人興奮的第一題，在前置環境等等都已經設定好後，我開始研究這題的Solidity 合約內容，這算是我第一次看，所以我決定要好好的仔細的理解整體脈絡跟用法，奠定一些基礎(在這次看完後我發現有些基礎是需要去稍微理解一下會更好)
2. 這個合約算較為單純，大致了解運作模式後，針對題目去理解，目標就是"成為owner"以及”用withdraw()來歸零”，參考了大神的sol後，由於我的環境並非unix，所以有部分的設定不太一樣，首先是使用$env:來設定環境變數(但.env還是得設定好)，再來就是在執行的部分，命令必須這樣設定
forge script script/solutions/01-Fallback.s.sol:FallbackSolution --fork-url [https://sepolia.infura.io/v3/](https://sepolia.infura.io/v3/a360f95dad004dc1bf712c848f72913b)MyprojectID
3. 後來就順利編譯完成並broadcast出去

--------------

今日回顧與思考：
1.在撰寫POC的部分，我可能還需要再加強Foundry的理解
2.關於Solidity合約已經有更多的了解了，但若後面要能夠越來越厲害，必須要加強基礎的部分
3.今天的我很棒，成功完成第一次的POC(雖然還是因為有大神在QAQ

------------

### 2024.09.04
**深入Solidity**

1.基本語法

```Solidity
SPDX-License-Identifier:MIT  --合約可以複製使用，但不負責任
SPDX-License-Identifier:UNLICENSED  --不希望被改寫或使用
pragma solidity ^ 0.7.0;  --0.7.0以上之版本均適用
pragma solidity >=0.7.0 < 0.9.0 --只適用於0.7.0~0.9.0之間

變數宣告型態(Variable)
string public myName = "Apple"; //字串的宣告
bool public myBooking = false; //布林值宣告
address public myAddress = 0xCXXXXX.....; //儲存地址的的宣告
uint public myNumber=0~2^n ; //無符號的整數宣告
uint256 public myUnit256=2^256-1 //uint後方加數字為256bits
int public myIntNumber=-1;  //有符號的整數宣告

狀態變數(State Variables)
unit value = 1 --在鏈上，可被所有合約訪問

局部變數(Local Variable)
function getValue() public view returns(uint){
	uint value = 1
} --只有呼叫這個函數時才會存在

contract myCounter{   --合約主體
  	--合約內的各種函式--
	constructor() {}; --構造函數，初始化合約的狀態變量
  	//最常初始化的是將owner=msg.sender，或是owner為一個可交易的地址
  	function Name() public/internal/external/private{};
		可見度--內外部/內部及繼承/外部，內部要用this.f()/純內部
	function Name() public view/pure/payable{};
		狀態修飾--只讀/不讀不寫/可接收以太幣	
	struct Name {參數1,參數2...}; --結構體，定義新的數據類型
	modifier Name() {require(參數1,參數2); _;}; --函式修飾器(修改函數行為)	
	mapping(key=>value) name; --映射，鍵對到值	
	event EventName(參數1,參數2...);--事件監聽	
	emit EventName(參數1,參數2...);--觸發event之指令	
	enum EnumName{參數1,參數2...};--列舉
}
```

2.Inherit(繼承)

```Solidity
pragma solidity ^0.7.0 ;
contract myContract1{ 
  uint256 private _myNumber;
  //myContract1使用的function為internal
  function getNumber1() internal view returns(uint256){
    return _myNumber;
  }
}
//「myContract2」繼承「myContract1」
contract  myContract2 is myContract1{  
  function getNumber2() private view returns(uint256){
  //可返回「myContract1」的function到「myContract2」的function
  return getNumber1();
  //也就是說，2繼承了1的getNumber1，1的設定為internal所以2也能用
  }
}
```

3.Constructor 的繼承

```Solidity
//A合約，有個name變量及一個構造函數，在部屬這個合約時需要傳遞一個字串'_name'，字串會被存在'name'中
contract A{
  string public name;
  constructor(string memory _name){
    name=_name;
  }
}
//B合約，有個text變量及一個構造函數，在部屬這個合約時需要傳遞一個字串'_text'，字串會被存在'text'中
contract B{
  string public text;
  constructor(string memory _text){
    text=_text;
  }
}

//第一種繼承方式
contract C is A("Ivy"),B("Ivy is a girl"){}
//合約C同時繼承'A'和'B'，也直接將Ivy傳給了A，將Ivy is a girl給B，所以不需要提供參數給C
//當我知道父合約的構造函數應該要接受什麼樣的參數並且不打算在子合約修改時可以使用

//第二種繼承方式
contract C is A,B{
  constructor(string memory _name,string memory _text) A(_name) B(_text) { }
}
//C繼承A和B但是沒有直接把參數給他們，而是在C的構造函數中才傳遞參數，所以當C部署時需要傳遞兩個參數
//較為靈活的方式來傳遞參數
```


### 2024.09.05
4.Array
```Solidity
//基本宣告
contract Array{
uint[] public dynamicArray; // 動態陣列(dynamic array)，可改變 
uint[3] public fixedArray; // 固定陣列(fixed array)-不可改變
uint[3] public wrongArray=[1,2,3,4]; //固定內容只有3個但你寫了4個會出錯
}
//使用Array
contract Array{
	uint[] public myArray=[1,2,3,4];
	function exemple() public {
		myArray.push(4); //輸出[1,2,3,4]
		uint x= myArray[1]; //輸出x=2
		myArray[2]=777; //輸出[1,2,777,4]
		myArray.pop(); //輸出[1,2,777] (刪除最後一個數字)
		delete myArray[1] ;//輸出[1,0,777,4](刪掉第二個數字)
	}
}
```

5.Struct 自定義結構體-創建遊戲角色

```Solidity
struct Person{ 
  //設定我的角色   
  string name;   
  uint olds;   
  string girl; 
}
//引用另一個Struct
struct home{ 
  //設定家的儲存結構   
  string homeAddress;  
  Person[] people; //調用剛剛做的struct
  mapping(uint=>Person[]) personIndex; //幫每一台車做編號 
}
//宣告方式
Person public person; //宣告為變數
Person[] public people;//宣告很多個人為變數

//在function裡面的宣告
function exemplePerson() public {
  // 位置宣告，直接依照順序賦值給Person，簡單明瞭，適合屬性清楚且固定
  Person memory person1 = Person("John", 30, "no");
  
  // 鍵值宣告，明確指定每個屬性的名稱，可以避免順序錯誤，屬性較多時適用
  Person memory person2 = Person({name: "Alice", olds: 25, girl: "yes"});
  
  // 逐步賦值，先宣告一個變數然後一個個給他們值，適合動態修改或處理的狀態
  Person memory person3;
  person3.name = "Bob";
  person3.olds = 40;
  person3.girl = "no";

  // 使用陣列和推送方法
  home storage myHome; //宣告一個myHome的變數，使用到home的結構
  //把剛剛宣告的person1放到myHome裡面，由於上面有宣告people是一個Person[]的陣列，所以用push
  myHome.people.push(person1);
  myHome.people.push(person2);
  myHome.people.push(person3);
  
  //將myHome.people陣列中的第0個元素拿出來，並存在_person變數中，算是一個修改屬性的行為
  Person storage _person = myHome.people[0];
  //把people[0]的年紀改成35歲了
  _person.olds = 35;
}
```

其中上面有使用到的Storage和Memory的差別
    - Storage：永久儲存在區塊鏈的變量
    - Memory：暫存的變量，用完就會被移除了
    - 所以上面那個Person storage _person = myHome.people[0];若把storage改成memory的話就沒辦法修改
    
6.Enum列舉
- 選擇狀態的列舉，和Struct很像，不過他是拿來描述"狀態”
- 例如:我們網購的時候，會有訂單的狀態-等待出貨、運送中、已到達

```Solidity
contract testEnum{  
	enum orderStatus{ 
	//列舉狀態      
	pending,   
	shipped,   
	completed,     
	} 
	//enum 可以宣告為狀態變數
	orderStatus public currentOrder;
	//Enum 可被 Struct使用
	//建立一個struct然後引用剛剛的列舉
	struct Order{   
	  address buyer;   
	  orderStatus status;  
	 }
	Order[] public orders;//將剛剛的struct宣告成陣列，可以放很多訂單	
	//用function來使用enum
	function get() public view returns(orderStatus) {
	  return currentOrder;//可以告訴你現在currentOrder的狀態，因為是view他只能看
	}
 function set(orderStatus _status) public {
	 currentOrder= _status;//他接受一個orderStatus型別的輸入，然後把他設定為currentOrder的值，你就能修改目前的訂單狀態
 }
 function ship() public {
	 currentOrder= orderStatus.shipped;//他直接將狀態改成運送中
 }
 function reset() public  {
	 delete currentOrder;//他會把currentOrder重置到pending
 }
}
```

---------

今天在思考將智能合約結合聯邦式學習是否可行
雖然學習的進度不快..但持續以自己的步調進行中
可能沒辦法寫太多學習的題目
但我相信我這些基底打完可以快速的成長的(?)吧
每天堅持來這邊撰寫，我就會進步的!

---------
<!-- Content_END -->
