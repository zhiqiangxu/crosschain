// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Utils {
    function bytesToBytes32(bytes memory _bs)
        internal
        pure
        returns (bytes32 value)
    {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            // load 32 bytes from memory starting from position _bs + 0x20 since the first 0x20 bytes stores _bs length
            value := mload(add(_bs, 0x20))
        }
    }

    function bytesToAddress(bytes memory _bs)
        internal
        pure
        returns (address addr)
    {
        require(_bs.length == 20, "bytes length does not match address");
        assembly {
            // for _bs, first word store _bs.length, second word store _bs.value
            // load 32 bytes from mem[_bs+20], convert it into Uint160, meaning we take last 20 bytes as addr (address).
            addr := mload(add(_bs, 0x14)) // data within slot is lower-order aligned: https://stackoverflow.com/questions/66819732/state-variables-in-storage-lower-order-aligned-what-does-this-sentence-in-the
        }
    }

    function addressToBytes(address _addr)
        internal
        pure
        returns (bytes memory bs)
    {
        assembly {
            bs := mload(0x40)
            mstore(bs, 0x14)
            mstore(add(bs, 0x20), shl(96, _addr))
            mstore(0x40, add(bs, 0x40))
        }
    }

    function sliceToBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32 result)
    {
        require(_bytes.length >= (_start + 32));
        assembly {
            result := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory tempBytes) {
        require(_bytes.length >= (_start + _length));

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(_length, 31)
                let iz := iszero(lengthmod)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iz))
                let end := add(mc, _length)

                for {
                    let cc := add(
                        add(add(_bytes, lengthmod), mul(0x20, iz)),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }
                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }
    }

    function bytesToUint256(bytes memory _bs)
        internal
        pure
        returns (uint256 value)
    {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            value := mload(add(_bs, 0x20))
        }
    }

    function uint256ToBytes(uint256 _value)
        internal
        pure
        returns (bytes memory bs)
    {
        assembly {
            bs := mload(0x40)
            mstore(bs, 0x20)
            mstore(add(bs, 0x20), _value)

            mstore(0x40, add(bs, 0x40))
        }
    }

    function containMAddresses(
        address[] memory _keepers,
        address[] memory _signers,
        uint256 _m
    ) internal pure returns (bool) {
        uint256 m = 0;
        for (uint256 i = 0; i < _signers.length; i++) {
            for (uint256 j = 0; j < _keepers.length; j++) {
                if (_signers[i] == _keepers[j]) {
                    m++;
                    if (j < _keepers.length) {
                        _keepers[j] = _keepers[_keepers.length - 1];
                    }
                    assembly {
                        mstore(_keepers, sub(mload(_keepers), 1))
                    }
                    break;
                }
            }
        }

        return m >= _m;
    }

    uint256 constant SIGNATURE_LEN = 65;

    function verifySigs(
        bytes32 hash,
        bytes memory _sigs,
        address[] memory _keepers,
        uint256 _m
    ) internal pure returns (bool) {
        uint256 sigCount = _sigs.length / SIGNATURE_LEN;
        address[] memory signers = new address[](sigCount);
        bytes32 r;
        bytes32 s;
        uint8 v;
        for (uint256 i = 0; i < sigCount; i++) {
            r = sliceToBytes32(_sigs, i * SIGNATURE_LEN);
            s = sliceToBytes32(_sigs, i * SIGNATURE_LEN + 32);
            v = uint8(_sigs[i * SIGNATURE_LEN + 64]);
            signers[i] = ecrecover(hash, v, r, s);
            if (signers[i] == address(0)) {
                return false;
            }
        }

        return containMAddresses(_keepers, signers, _m);
    }

    function dedupAddress(address[] memory _dup)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory dedup = new address[](_dup.length);
        uint256 idx = 0;
        bool dup;
        for (uint256 i = 0; i < _dup.length; i++) {
            dup = false;
            for (uint256 j = 0; j < dedup.length; j++) {
                if (_dup[i] == dedup[j]) {
                    dup = true;
                    break;
                }
            }
            if (!dup) {
                dedup[idx] = _dup[i];
                idx += 1;
            }
        }
        assembly {
            mstore(dedup, idx)
        }

        return dedup;
    }
}
