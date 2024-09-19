```
function abortMission() external onlyRole(CAPTAIN) {
        require(distance() < 1_000_000e18, "Must be within 1000km to abort mission");
        require(payloadMass < 1_000e18, "Must be weigh less than 1000kg to abort mission");
        require(numArea51Visits > 0, "Must visit Area 51 and scare the humans before aborting mission");
        require(msg.sender.codehash != keccak256("")); // Require that msg.sender has code (or is an empty account which isn't possible)
        missionAborted = true;
        emit MissionAborted();
    }
```
    
**1. distance() < 1_000_000e18**

distance()-> _calculateDistance(position.x, position.y, position.z)

position.x,y,z 預設太大了
```
        position.x = 1_000_000e18;
        position.y = 2_000_000e18;
        position.z = 3_000_000e18;
```
因此 `function jumpThroughWormhole(int256 x, int256 y, int256 z) external onlyRole(CAPTAIN)`
重設一下position.x,y,z, 

    1. jumpThroughWormhole第一關 !wormholesEnabled (pass)
    2. 第二關 payloadMass >= 1_000e18, payloadMass預設5000
    3. 第三關 新傳入的x,y,z 要小於等於 `100_000`
    4. payloadMass 會變為原本的兩倍 -> `10_000`
    
    
**2.payloadMass < 1_000e18**
目前`payloadMass = 10_000`
所以要先減少
`function dumpPayload(uint256 _amount) external onlyRole(ENGINEER)`
要*ENGINEER role* 才行呼叫
-> `function applyForJob(bytes32 role)` applyfor enginner
-> amount = 9001
至此`payloadMass = 999`

**3. numArea51Visits > 0**
預設`numArea51Visits = 0`

```
    function visitArea51(address _secret) external onlyRole(CAPTAIN) {
        // Secret is such that msg.sender + _secret mod 2**160 == 51.
        require(_uncheckedAdd160(uint160(msg.sender), uint160(_secret)) == uint160(51));

        numArea51Visits = _uncheckedIncrement(numArea51Visits);

        position.x = 51_000_000e18;
        position.y = 51_000_000e18;
        position.z = 51_000_000e18;

        emit PositionChanged(msg.sender, position.x, position.y, position.z);
    }
```
caller 需要為 `CAPTAIN`

-> 要當 `CAPTAIN` 要先當 `PHYSICIST`
-> applyForJob(PHYSICIST)
    ->(role == PHYSICIST && roles[address(this)].role == ENGINEER)
    -> AlienSpaceship合約同時要是ENGINEER
    -> 用 `function runExperiment`呼叫 `(abi.encodeWithSignature("applyForJob(bytes32)", alienSpaceship.ENGINEER())`
-> applyForPromotion(CAPTAIN) 最少要當12秒 `PHYSICIST` 才能變成`CAPTAIN`
-> `wormholesEnabled = true` 要先呼叫 `function enableWormholes() external onlyRole(PHYSICIST)`
    ->`function enableWormholes()` 中 `require(msg.sender.codehash == keccak256("")); // Require that msg.sender has no code. This must be called within the constructor of a contract`
    -> 所以要在constructor中先執行
-> 身份搞定了 回到 `function visitArea51(address _secret)`

```_uncheckedAdd160(uint160(msg.sender), uint160(_secret)) == uint160(51)```

secret = 51 - uint160(msg.sender)+

-> 隨後 position.x,y,z又會變得超遠 -->  再jumpThroughWormhole

---
再整理一次

    

