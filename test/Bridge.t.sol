// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BridgeProxy.sol";

contract BridgeTest is Test {
    BridgeProxy public bridge;

    function setUp() public {
        address[] memory keepers = new address[](3);
        keepers[0] = address(0x01);
        keepers[1] = address(0x02);
        keepers[2] = address(0x03);
        bridge = new BridgeProxy();
    }
}
