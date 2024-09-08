pragma solidity 0.8.20;

contract Test {
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );
    struct DepositEventData {
        bytes pubkey;
        bytes withdrawal_credentials;
        bytes amount;
        bytes signature;
        bytes index;
    }


    bytes DEPOSIT_AMOUNT_KECCAK = to_little_endian_64(uint64(FAIR_DEPOSIT_AMOUNT / 1 gwei));

    bytes1 constant ETH1_ADDRESS_WITHDRAWAL_PREFIX = hex"01";

    function emitEvent() public {
        DepositEventData memory d;
        d.pubkey = "";
        d.withdrawal_credentials = eth1WithdrawalCredentials();
        d.amount = DEPOSIT_AMOUNT_KECCAK;
        d.signature = "";
        d.index = "";

        bytes32 selector = DepositEvent.selector;

        bytes memory data = abi.encode(d);
        assembly {
            log1(add(data, 0x20), mload(data), selector)
        }
        //emit DepositEvent(
        //    "",
        //    eth1WithdrawalCredentials(),
        //    DEPOSIT_AMOUNT_KECCAK,
        //    "",
        //    ""
        //);
    }

    function get_deposit_root() external view returns (bytes32) {
        revert("DepositContract: deposit value too high");
    }


    uint256 constant FAIR_DEPOSIT_AMOUNT = 16 ether;

    function to_little_endian_64(
        uint64 value
    ) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }



    function eth1WithdrawalCredentials()
        internal
        view
        returns (bytes memory creds)
    {
        return
            abi.encodePacked(
                ETH1_ADDRESS_WITHDRAWAL_PREFIX,
                uint248(uint160(address(0xa1755DF9111a04990D553963eFf1A364191c9b02)))
            );
    }

}

