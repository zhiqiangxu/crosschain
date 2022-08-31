// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridgeData {
    function isInWhiteListFrom(address _addr) external view returns (bool);

    function isInWhiteListTo(address _addr) external view returns (bool);

    function updateKeepersFromLogic(address[] calldata _newKeepers) external;

    function markDoneFromLogic(uint16 _srcChainID, uint256 _nonce) external;

    function getKeepers() external view returns (address[] memory);

    function chainID() external view returns (uint16);
}
