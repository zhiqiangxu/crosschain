// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IReceiver {
    function onReceive(
        uint16 _srcChainID,
        bytes calldata _srcAddress,
        uint256 _nonce,
        bytes calldata _payload
    ) external returns (bool);
}
