// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/libs/Utils.sol";

contract UtilsTest is Test {
    function testSlice(bytes memory s) public {
        assertEq(Utils.slice(s, 0, 0).length, 0, "1");

        bytes memory slice = Utils.slice(s, 0, s.length / 2);
        assertEq(slice.length, s.length / 2, "2");
        for (uint256 i = 0; i < slice.length; i++) {
            assertEq(slice[i], s[i], "3");
        }
    }

    function testContainMAddresses(address[] memory dup_keepers) public {
        address[] memory keepers = Utils.dedupAddress(dup_keepers);

        assertLe(keepers.length, dup_keepers.length);

        address[] memory signers = new address[](keepers.length / 2);
        for (uint256 i = 0; i < signers.length; i++) {
            signers[i] = keepers[i];
        }

        uint256 old = keepers.length;
        assertEq(
            Utils.containMAddresses(keepers, signers, signers.length),
            true,
            "1"
        );
        assertEq(old - signers.length, keepers.length, "2");

        assertEq(Utils.containMAddresses(keepers, signers, 1), false, "3");
    }

    function testBytes32(bytes32 v1) public {
        uint256 copy = uint256(v1);
        bytes32 v2 = v1;
        v2 = keccak256(abi.encode(v2));
        assertEq(copy, uint256(v1));
    }

    function testBytes(bytes memory v1) public {
        vm.assume(v1.length > 0 && v1[0] != 0x01);
        bytes memory v2 = v1;
        v2[0] = 0x01;
        assertEq(v1[0] != 0x01, false);
    }
}
