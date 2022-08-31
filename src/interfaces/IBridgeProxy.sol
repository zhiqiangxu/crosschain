// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridgeProxy {
    function logic() external returns (address);

    function sendFromLogic(
        address sender,
        uint16 _dstChainID,
        bytes calldata _destination,
        bytes calldata _payload
    ) external;

    function receivePayloadFromLogic(
        uint16 _srcChainID,
        uint256 _nonce,
        bytes calldata _srcAddress,
        address _dstAddress,
        bytes calldata _payload,
        uint256 _gasLimit
    ) external;
}
