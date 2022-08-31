// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BridgeProxy.sol";
import "../src/BridgeData.sol";
import "../src/BridgeLogic.sol";

contract BridgeTest is Test {
    BridgeProxy public proxy;
    BridgeData public data;
    BridgeLogic public logic;

    uint16 public srcChainID;
    uint16 public dstChainID;
    uint256 pk1;
    uint256 pk2;
    uint256 pk3;

    function setUp() public {
        srcChainID = 1;
        dstChainID = 2;
        pk1 = 1;
        pk2 = 2;
        pk3 = 3;

        address[] memory keepers = new address[](3);
        keepers[0] = address(vm.addr(pk1));
        keepers[1] = address(vm.addr(pk2));
        keepers[2] = address(vm.addr(pk3));
        proxy = new BridgeProxy();
        data = new BridgeData(srcChainID, address(proxy), keepers);
        logic = new BridgeLogic(address(proxy), address(data));
        proxy.upgradeLogic(address(logic));
    }

    function testSend() external {
        data.addWhiteListFrom(address(this));
        logic.send(dstChainID, Utils.addressToBytes(address(0)), bytes(""));
    }

    function onReceive(
        uint16,
        bytes calldata,
        uint256,
        bytes calldata
    ) external pure returns (bool) {
        return true;
    }

    function testReceive(
        uint16 _srcChainID,
        uint256 _nonce,
        address _srcAddress,
        bytes memory _payload
    ) external {
        address _dstAddress = address(this);
        data.addWhiteListTo(_dstAddress);

        bytes32 hash = keccak256(
            abi.encodePacked(
                _srcChainID,
                data.chainID(),
                _nonce,
                _srcAddress,
                _dstAddress,
                _payload
            )
        );
        bytes memory sigs = bytes("");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk1, hash);
        address signer = ecrecover(hash, v, r, s);
        assertEq(signer, vm.addr(pk1));

        sigs = abi.encodePacked(sigs, r, s, v);
        (v, r, s) = vm.sign(pk2, hash);
        sigs = abi.encodePacked(sigs, r, s, v);
        (v, r, s) = vm.sign(pk3, hash);
        sigs = abi.encodePacked(sigs, r, s, v);

        assertEq(sigs.length, 65 * 3);

        logic.receivePayload(
            _srcChainID,
            _nonce,
            Utils.addressToBytes(_srcAddress),
            _dstAddress,
            _payload,
            sigs,
            200000
        );
    }
}
