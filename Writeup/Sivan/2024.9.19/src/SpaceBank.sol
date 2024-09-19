pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFlashLoanReceiver {
    function executeFlashLoan(uint256 amount) external;
}

contract SpaceBank {
    //Number of alarm activations
    uint256 EmergencyAlarms;
    //Token of the bank
    IERC20 public token;
    //Depositor balances
    mapping(address => uint256) public balances;
    //reentrancy protection
    bool entered;

    uint256 internal gasLimit0 = 9999999999999999999999999; //@TODO calculate these gas limit values to be as small as possible

    uint256 internal gasLimit1 = 9999999999999999999999999;

    address internal _createdAddress;

    uint256 alarmTime;

    bool public exploded;

    bool locked; //If this is true the bank will be locked forever.

    modifier _emergencyAlarms(bytes calldata data) {
        if (entered = true) {
            EmergencyAlarms++; //Sound the alarm and activate the security protocol
            _emergencyAlarmProtocol(data);
        }
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    function gasLimits() internal view returns (uint256) {
        if (EmergencyAlarms == 1) return gasLimit0;
        if (EmergencyAlarms == 2) return gasLimit1;
    }

    //Deposit into the bank
    function deposit(uint256 amount, bytes calldata data) external _emergencyAlarms(data) {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
    }

    //Withdraws from the bank
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    //Takes a flashloan from the bank
    function flashLoan(uint256 amount, address flashLoanReceiver) external {
        uint256 initialBalance = token.balanceOf(address(this));

        require(initialBalance >= amount, "Not enough liquidity");
        // Transfer loan amount to the receiver
        require(token.transfer(flashLoanReceiver, amount), "Transfer failed");

        // Execute custom logic in the receiver's contract
        entered = true;

        (bool success, bytes memory result) =
            flashLoanReceiver.call(abi.encodeWithSignature("executeFlashLoan(uint256)", amount));
        if (success == false) revert(string(result));
        entered = false;
        uint256 fee = amount / 1000; // 0.1% fee
        uint256 currentBalance = token.balanceOf(address(this));
        require(currentBalance >= initialBalance + fee, "Loan not repaid with fee");
    }

    //Alarms will be activated to protect from thiefs
    function _emergencyAlarmProtocol(bytes memory data) internal {
        if (EmergencyAlarms == 1) {
            //first alarm
            uint256 MagicNumber = block.number;

            uint256 x = abi.decode(data, (uint256));
            require(x == MagicNumber % 47, "Wrong passphrase");
        }
        if (EmergencyAlarms == 2) {
            //second alarm
            bytes32 MagicNumber = bytes32(block.number);
            uint256 balance = address(this).balance;
            address newContractAddress;
            assembly {
                newContractAddress := create2(0, add(data, 0x20), mload(data), MagicNumber)
            }
            require(address(this).balance > balance, "You need to send ether to pass through security");
            _createdAddress = newContractAddress;
            alarmTime = block.number;
        }
        if (EmergencyAlarms == 3) {
            revert("Third alarm, bank is locked");
        }
    }

    ///Make the bank explode
    function explodeSpaceBank() external {
        require(block.number == alarmTime + 2, "Can't explode the bank");
        uint256 codeSize;
        address value = _createdAddress;
        assembly {
            codeSize := extcodesize(value)
        }
        require(codeSize == 0, "You were caught");
        require(token.balanceOf(address(this)) == 0, "The bank still has funds");
        exploded = true;
    }
}

contract SpaceToken is ERC20, Ownable {
    constructor() ERC20("SpaceToken", "Space") Ownable() {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}