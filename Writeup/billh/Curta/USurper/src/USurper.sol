// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract Throne {
    DAO public dao;

    mapping(address => bool) public usurpers;
    mapping(uint256 => bool) public thrones;

    constructor() {
        address[] memory allowedTargets = new address[](1);
        allowedTargets[0] = address(this);

        bytes4[] memory allowedMethods = new bytes4[](1);
        allowedMethods[0] = Throne.forgeThrone.selector;
        // no usurpers allowed

        dao = new DAO(allowedTargets, allowedMethods);
    }

    function name() external pure returns (string memory) {
        return "Usurper's Throne";
    }

    modifier onlyDAO() {
        require(msg.sender == address(dao), "only the DAO can add winners");
        _;
    }

    function addUsurper(address who) external onlyDAO {
        usurpers[who] = true;
    }

    function forgeThrone(uint256 throne) external onlyDAO {
        thrones[throne] = true;
    }

    function generate(address seed) external view returns (uint256) {
        return uint256(uint160(seed));
    }

    function verify(uint256 seed, uint256 solution) external view returns (bool) {
        address solver = address(uint160(seed));
        require(solution == uint256(keccak256(abi.encode(solver))));
        return usurpers[solver] && thrones[solution];
    }
}

contract DAO {
    // gotta go fast
    uint256 constant REQUIRED_VOTES = 3;
    uint256 constant DURATION = 36;

    mapping(address => bool) targets;
    mapping(bytes4 => bool) methods;

    struct Proposal {
        address owner;
        uint64 end;
        uint32 votes;
        address target;
        bool executed;
    }

    mapping(uint256 => Proposal) proposals;
    mapping(address => mapping(uint256 => bool)) voted;

    constructor(address[] memory allowedTargets, bytes4[] memory allowedMethods) {
        for (uint256 i = 0; i < allowedTargets.length; i++) {
            targets[allowedTargets[i]] = true;
        }

        for (uint256 i = 0; i < allowedMethods.length; i++) {
            methods[allowedMethods[i]] = true;
        }
    }

    modifier onlyOwner(uint256 id) {
        require(msg.sender == proposals[id].owner, "only proposal owner allowed");
        _;
    }

    function validData(bytes memory data) internal view returns (bool) {
        return data.length >= 4 && methods[bytes4(data)];
    }

    function validTarget(address target) internal view returns (bool) {
        return targets[target];
    }

    function descriptionKey(uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encode(id, id));
    }

    function getDescription(uint256 id) public view returns (string memory) {
        return string(CheapMap.read(descriptionKey(id)));
    }

    function setDescription(uint256 id, string memory desc) internal {
        CheapMap.write(descriptionKey(id), bytes(desc));
    }

    function getData(uint256 id) public view returns (bytes memory) {
        return CheapMap.read(bytes32(id));
    }

    function setData(uint256 id, bytes memory data) internal {
        require(validData(data), "payload data not allowed");
        CheapMap.write(bytes32(id), data);
    }

    function createProposal(
        uint256 id,
        address target,
        bytes memory data,
        string memory desc
    ) external {
        require(proposals[id].owner == address(0), "proposal already exists");
        require(validTarget(target), "invalid payload target");

        proposals[id] = Proposal(
            msg.sender,
            uint64(block.timestamp + DURATION),
            1,
            target,
            false
        );

        setData(id, data);
        if (bytes(desc).length > 0) setDescription(id, desc);
    }

    function vote(uint256 id) external {
        Proposal storage proposal = proposals[id];
        require(proposal.owner != address(0), "proposal does not exist");
        require(block.timestamp <= uint256(proposal.end), "proposal ended");
        require(!voted[msg.sender][id], "already voted");
        voted[msg.sender][id] = true;
        proposal.votes++;
    }

    function execute(uint256 id) external returns (bytes memory) {
        require(
            proposals[id].votes >= REQUIRED_VOTES,
            "not enough votes"
        );
        require(
            !proposals[id].executed,
            "already executed"
        );

        (bool success, bytes memory result) = proposals[id].target.call(
            getData(id)
        );
        proposals[id].executed = success;
        return result;
    }
}

library CheapMap {
  //                                         keccak256(bytes('CheapMap.slot'))
  bytes32 private constant SLOT_KEY_PREFIX = 0x06fccbac10f612a9037c3e903b4f4bd03ffbc103781cbe821d25b33299e50efb;

  function internalKey(bytes32 _key) internal pure returns (bytes32) {
    return keccak256(abi.encode(SLOT_KEY_PREFIX, _key));
  }

  function write(string memory _key, bytes memory _data) internal returns (address pointer) {
    return write(keccak256(bytes(_key)), _data);
  }

  function write(bytes32 _key, bytes memory _data) internal returns (address pointer) {
    bytes memory code = Bytecode.creationCodeFor(_data);
    pointer = Creator.create(internalKey(_key), code);
  }

  function read(string memory _key) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)));
  }

  function read(string memory _key, uint256 _start) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start);
  }

  function read(string memory _key, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start, _end);
  }

  function read(bytes32 _key) internal view returns (bytes memory) {
    return Bytecode.codeAt(Creator.addressOf(internalKey(_key)), 0, type(uint256).max);
  }

  function read(bytes32 _key, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(Creator.addressOf(internalKey(_key)), _start, type(uint256).max);
  }

  function read(bytes32 _key, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(Creator.addressOf(internalKey(_key)), _start, _end);
  }
}

library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        oCode := mload(0x40)
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        mstore(oCode, size)
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

library Creator {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();

  bytes internal constant PROXY_CHILD_BYTECODE = hex"68_36_3d_3d_37_36_3d_34_f0_ff_3d_52_60_09_60_17_f3_ff";
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x648b59bcbb41c37892d3b820522dc8b8c275316bb020f043a9068f607abeb810;

  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  function create(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    return create(_salt, _creationCode, 0);
  }

  function create(bytes32 _salt, bytes memory _creationCode, uint256 _value) internal returns (address addr) {
    bytes memory creationCode = PROXY_CHILD_BYTECODE;
    addr = addressOf(_salt);
    address proxy; assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();
    (bool success,) = proxy.call{ value: _value }(_creationCode);
    if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
  }

  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
  }
}
