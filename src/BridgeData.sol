// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IBridgeData.sol";
import "./interfaces/IBridgeProxy.sol";

contract BridgeData is IBridgeData, Ownable {
    uint16 public immutable chainID;
    address public immutable proxy;

    address[] private keepers;

    mapping(address => bool) public whiteListFromMap;
    mapping(address => bool) public whiteListToContractMap;
    mapping(uint16 => mapping(uint256 => bool)) doneMap;

    constructor(
        uint16 _chainID,
        address _proxy,
        address[] memory _keepers
    ) {
        chainID = _chainID;
        proxy = _proxy;
        keepers = _keepers;
    }

    function getKeepers() external view returns (address[] memory) {
        return keepers;
    }

    function addWhiteListFrom(address addr) external onlyOwner {
        whiteListFromMap[addr] = true;
    }

    function delWhiteListFrom(address addr) external onlyOwner {
        delete whiteListFromMap[addr];
    }

    function addWhiteListTo(address addr) external onlyOwner {
        whiteListToContractMap[addr] = true;
    }

    function delWhiteListTo(address addr) external onlyOwner {
        delete whiteListToContractMap[addr];
    }

    function markDoneFromLogic(uint16 _srcChainID, uint256 _nonce) external {
        require(msg.sender == IBridgeProxy(proxy).logic());

        require(!doneMap[_srcChainID][_nonce], "ALREADY_DONE");
        doneMap[_srcChainID][_nonce] = true;
    }

    function updateKeepersFromLogic(address[] calldata _newKeepers) external {
        require(msg.sender == IBridgeProxy(proxy).logic(), "INVALID_SENDER");

        keepers = _newKeepers;
    }

    function isInWhiteListFrom(address addr)
        external
        view
        override
        returns (bool)
    {
        return whiteListFromMap[addr];
    }

    function isInWhiteListTo(address addr)
        external
        view
        override
        returns (bool)
    {
        return whiteListToContractMap[addr];
    }
}
