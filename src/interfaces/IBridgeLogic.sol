// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridgeLogic {
    function send(
        uint16 _dstChainID,
        bytes calldata _destination,
        bytes calldata _payload
    ) external;

    function receivePayload(
        uint16 _srcChainID,
        uint256 _nonce,
        bytes calldata _srcAddress,
        address _dstAddress,
        bytes calldata _payload,
        bytes calldata _sigs,
        uint256 _gasLimit
    ) external;

    function updateKeepers(address[] calldata _newKeepers, bytes calldata _sigs)
        external;
}
