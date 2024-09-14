// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract AirdropDistributor {
    IWETH public immutable weth;
    uint256 constant claimableAmount = 100 ether;

    constructor(IWETH _weth) payable {
        require(
            msg.value == claimableAmount,
            "AirdropDistributor: wrong amount"
        );

        weth = _weth;
        _weth.deposit{value: claimableAmount}();
    }

    function claim(string calldata password) external returns (uint256) {
        require(
            keccak256(abi.encodePacked(password)) == keccak256("m3f80"),
            "AirdropDistributor: wrong password"
        );
        require(tx.origin != msg.sender, "AirdropDistributor: no EOA");

        (bool s, ) = address(0x0).delegatecall(
            abi.encodeWithSignature("go(bytes[])", new bytes[](0))
        );
        require(s, "AirdropDistributor: failed to call");

        weth.transfer(msg.sender, claimableAmount);
        return claimableAmount;
    }
}

contract FrontrunBot {
    error CallFailed(uint256 index);
    error OnlyOwner();

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function go(bytes[] calldata data) external payable onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            (
                bool isDelegatecall,
                address target,
                uint256 value,
                bytes memory payload
            ) = abi.decode(data[i], (bool, address, uint256, bytes));

            bool success;

            if (isDelegatecall) {
                (success, ) = target.delegatecall(payload);
            } else {
                (success, ) = target.call{value: value}(payload);
            }

            if (!success) {
                revert CallFailed(i);
            }
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }

        _;
    }
}

contract Challenge {
    IWETH public immutable weth;
    FrontrunBot public immutable bot;
    AirdropDistributor public immutable airdropDistributor;

    uint256 constant amount = 500 ether;
    uint256 constant claimableAmount = 100 ether;

    constructor(IWETH _weth, FrontrunBot _bot) payable {
        require(
            msg.value == amount + claimableAmount,
            "Challenge: wrong amount"
        );

        airdropDistributor = new AirdropDistributor{value: claimableAmount}(
            _weth
        );
        weth = _weth;
        bot = _bot;

        weth.deposit{value: amount}();
        weth.transfer(address(_bot), amount);
    }

    function claim(string calldata password) external {
        uint256 value = airdropDistributor.claim(password);
        weth.transfer(msg.sender, value);
    }

    function isSolved() external view returns (bool) {
        return weth.balanceOf(address(this)) > amount + claimableAmount / 3;
    }
}
