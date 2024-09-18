// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Bytecode level for Ethernaut
/// @author Steven E. Thornton
/// @notice The goal is to sucessfully call abortMission and set missionAborted to true. The
/// source for this level will never be revealed so any comments giving away the solution
/// will not be seen.
contract AlienSpaceship {
    // Available roles
    bytes32 public constant ENGINEER = keccak256("ENGINEER");
    bytes32 public constant PHYSICIST = keccak256("PHYSICIST");
    bytes32 public constant CAPTAIN = keccak256("CAPTAIN");
    bytes32 public constant BLOCKCHAIN_SECURITY_RESEARCHER = keccak256("BLOCKCHAIN_SECURITY_RESEARCHER");

    struct Employee {
        bytes32 role; // One of the available roles
        uint256 time; // Time they were hired/promoted
        bool enabledTheWormholes; // Set to true when they enable wormholes. Required for promotion from PHYSICIST to CAPTAIN
    }

    // Tracking of roles by address. There can be multiple addresses with the same role.
    // Only the above roles are available or no role: bytes32(0).
    mapping(address => Employee) public roles;

    // Can only jump through wormholes (jumpThroughWormhole) if a PHYSICIST has enabled them (enableWormholes)
    bool public wormholesEnabled;

    // The goal of the level is to set this to true
    bool public missionAborted;

    // Number of times Area 51 has been visited
    uint256 public numArea51Visits;

    // Position in space
    struct Position {
        int256 x;
        int256 y;
        int256 z;
    }

    Position public position;

    // Payload mass in kg
    uint256 public payloadMass;

    // ---------------------------------------- //
    // EVENTS                                   //
    // ---------------------------------------- //
    event WormholesEnabled();
    event Hired(address indexed applicant, bytes32 indexed role);
    event Promoted(address indexed employee, bytes32 indexed oldRole, bytes32 indexed newRole);
    event Quit(address indexed employee, bytes32 indexed role);
    event PayloadChanged(address indexed employee, uint256 oldMass, uint256 newMass);
    event PositionChanged(address indexed employee, int256 x, int256 y, int256 z);
    event MissionAborted();

    /**
     * @dev Sets the initial payloadMass to 5,000kg
     * @dev Sets the initial position to (1000000m, 2000000m, 3000000m)
     */
    constructor() {
        payloadMass = 5_000e18;
        position.x = 1_000_000e18;
        position.y = 2_000_000e18;
        position.z = 3_000_000e18;
    }

    // ---------------------------------------- //
    // PUBLIC VIEW FUNCTIONS                    //
    // ---------------------------------------- //

    /**
     * Distance to the alien spaceship in meters
     * @return Distance
     */
    function distance() public view returns (uint256) {
        return _calculateDistance(position.x, position.y, position.z);
    }

    // ---------------------------------------- //
    // EXTERNAL FUNCTIONS                       //
    // ---------------------------------------- //

    /**
     * Enable wormholes for jumping
     * @dev Only callable by a PHYSICIST
     */
    function enableWormholes() external onlyRole(PHYSICIST) {
        require(msg.sender.codehash == keccak256("")); // Require that msg.sender has no code. This must be called within the constructor of a contract
        wormholesEnabled = true;
        roles[msg.sender].enabledTheWormholes = true;
        emit WormholesEnabled();
    }

    /**
     * Jump to new co-ordinates (x, y, z) by jumping through a wormhole.
     * @dev This function will never revert.
     * @dev Only callable by a CAPTAIN
     * @param x x-coordinate to jump to
     * @param y y-coordinate to jump to
     * @param z z-coordinate to jump to
     */
    function jumpThroughWormhole(int256 x, int256 y, int256 z) external onlyRole(CAPTAIN) returns (string memory) {
        if (!wormholesEnabled) {
            return "Wormholes are disabled";
        }
        if (payloadMass >= 1_000e18) {
            return "Must weigh less than 1,000kg to jump through wormhole";
        }
        if (_calculateDistance(x, y, z) <= 100_000e18) {
            return "Cannot get closer than 100km or the enemy will detect us!";
        }

        position.x = x;
        position.y = y;
        position.z = z;

        emit PositionChanged(msg.sender, x, y, z);

        // Jumping through wormholes causes the payloadMass to double
        uint256 oldPayloadMass = payloadMass;
        payloadMass = 2 * oldPayloadMass;
        emit PayloadChanged(msg.sender, oldPayloadMass, payloadMass);

        return "You've almost solved the level!";
    }

    /**
     * The caller can submit an application for a given role. The application
     * may be successful (they will be granted the role), or rejected.
     * @param role Role to apply for.
     */
    function applyForJob(bytes32 role) external validateRole(role) {
        bytes32 currentRole = roles[msg.sender].role;

        if (currentRole == bytes32(0)) {
            if (role == ENGINEER) {
                roles[msg.sender].role = ENGINEER;
                roles[msg.sender].time = block.timestamp;
                emit Hired(msg.sender, ENGINEER);
            } else if (role == PHYSICIST && roles[address(this)].role == ENGINEER) {
                roles[msg.sender].role = PHYSICIST;
                roles[msg.sender].time = block.timestamp;
                emit Hired(msg.sender, PHYSICIST);
            } else if (role == BLOCKCHAIN_SECURITY_RESEARCHER) {
                revert(
                    "There is no blockchain security researcher position on the spaceship but we've heard that OpenZeppelin is hiring :)"
                );
            } else {
                revert("Role is not hiring");
            }
        } else {
            revert("Use the applyForPromotion function to get promoted");
        }
    }

    /**
     * Allows to be promoted from a PHYSICIST to a CAPTAIN.
     * @dev To be promoted, you must hold the PHYSICIST role for at least one block (12 seconds)
     */
    function applyForPromotion(bytes32 role) external validateRole(role) {
        if (role == CAPTAIN && roles[msg.sender].role == PHYSICIST) {
            require(
                roles[msg.sender].time + 12 <= block.timestamp,
                "You must hold a position for at least 12 seconds before being eligible for promotion"
            );
            require(roles[msg.sender].enabledTheWormholes);
            roles[msg.sender].role = CAPTAIN;
            roles[msg.sender].time = block.timestamp;
            emit Promoted(msg.sender, PHYSICIST, CAPTAIN);
        } else {
            revert("Promotion not available");
        }
    }

    /**
     * Allow msg.sender to "quit" their job (role).
     * Resets their role to 0
     */
    function quitJob() external {
        bytes32 currentRole = roles[msg.sender].role;
        require(currentRole != bytes32(0), "Cannot quit if you don't have a job");
        delete roles[msg.sender];
        emit Quit(msg.sender, currentRole);
    }

    /**
     * Run an experiment.
     * @dev Only ENGINEER role members can run experiments.
     * @param _data Calldata passed to address(this)
     */
    function runExperiment(bytes calldata _data) external onlyRole(ENGINEER) {
        (bool success,) = address(this).call(_data);
        require(success, "Experiment failed!");
    }

    /**
     * Dumps some of the payload
     * @dev Must keep more than 500kg on the spaceship
     * @dev Only callable by an ENGINEER
     * @param _amount Amount to dump in kg
     */
    function dumpPayload(uint256 _amount) external onlyRole(ENGINEER) {
        require(_amount <= payloadMass, "Cannot dump more than what exists");
        uint256 oldPayloadMass = payloadMass;
        uint256 newPayloadMass = oldPayloadMass - _amount;
        require(newPayloadMass > 500e18, "Need to keep some food around");
        payloadMass = newPayloadMass;
        emit PayloadChanged(msg.sender, oldPayloadMass, newPayloadMass);
    }

    /**
     * Sets the co-ordinates to "Area 51"
     * @dev The input _secret must be such that msg.sender + _secret mod 2**160 == 51
     * @dev Increments the numArea51Visits value
     * @dev Only callable by a CAPTAIN
     * @param _secret Secret value required to visit are 51.
     */
    function visitArea51(address _secret) external onlyRole(CAPTAIN) {
        // Secret is such that msg.sender + _secret mod 2**160 == 51.
        require(_uncheckedAdd160(uint160(msg.sender), uint160(_secret)) == uint160(51));

        numArea51Visits = _uncheckedIncrement(numArea51Visits);

        position.x = 51_000_000e18;
        position.y = 51_000_000e18;
        position.z = 51_000_000e18;

        emit PositionChanged(msg.sender, position.x, position.y, position.z);
    }

    /**
     * Abort the mission. Successfully calling this function solves the level.
     * @dev Only callable by a CAPTAIN
     */
    function abortMission() external onlyRole(CAPTAIN) {
        require(distance() < 1_000_000e18, "Must be within 1000km to abort mission");
        require(payloadMass < 1_000e18, "Must be weigh less than 1000kg to abort mission");
        require(numArea51Visits > 0, "Must visit Area 51 and scare the humans before aborting mission");
        require(msg.sender.codehash != keccak256("")); // Require that msg.sender has code (or is an empty account which isn't possible)
        missionAborted = true;
        emit MissionAborted();
    }

    // ---------------------------------------- //
    // PRIVATE FUNCTIONS                        //
    // ---------------------------------------- //

    function _abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    // L1 norm
    function _calculateDistance(int256 x, int256 y, int256 z) private pure returns (uint256) {
        return uint256(_abs(x) + _abs(y) + _abs(z));
    }

    // Unchecked addition of uint160
    function _uncheckedAdd160(uint160 a, uint160 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    // Unchecked increment
    function _uncheckedIncrement(uint256 a) private pure returns (uint256) {
        unchecked {
            return a + 1;
        }
    }

    // ---------------------------------------- //
    // MODIFIERS                                //
    // ---------------------------------------- //

    // Validate that msg.sender has the input _role
    modifier onlyRole(bytes32 _role) {
        require(roles[msg.sender].role == _role, "Invalid role");
        _;
    }

    // Validate that the input _role is a valid role.
    modifier validateRole(bytes32 _role) {
        if (!(_role == PHYSICIST || _role == ENGINEER || _role == CAPTAIN || _role == BLOCKCHAIN_SECURITY_RESEARCHER)) {
            revert("Invalid role");
        }
        _;
    }
}