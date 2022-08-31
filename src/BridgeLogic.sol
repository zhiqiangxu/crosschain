// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IBridgeLogic.sol";
import "./interfaces/IBridgeProxy.sol";
import "./libs/Utils.sol";
import "./interfaces/IBridgeData.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BridgeLogic is IBridgeLogic, Ownable, Pausable {
    address private immutable proxyAddr;
    address private immutable dataAddr;

    constructor(address _proxyAddr, address _dataAddr) {
        proxyAddr = _proxyAddr;
        dataAddr = _dataAddr;
    }

    function send(
        uint16 _dstChainID,
        bytes calldata _destination,
        bytes calldata _payload
    ) external override whenNotPaused {
        require(
            IBridgeData(dataAddr).isInWhiteListFrom(msg.sender),
            "INVALID_FROM"
        );

        IBridgeProxy(proxyAddr).sendFromLogic(
            msg.sender,
            _dstChainID,
            _destination,
            _payload
        );
    }

    function receivePayload(
        uint16 _srcChainID,
        uint256 _nonce,
        bytes calldata _srcAddress,
        address _dstAddress,
        bytes calldata _payload,
        bytes calldata _sigs,
        uint256 _gasLimit
    ) external override {
        require(
            IBridgeData(dataAddr).isInWhiteListTo(_dstAddress),
            "INVALID_TO"
        );

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    _srcChainID,
                    IBridgeData(dataAddr).chainID(),
                    _nonce,
                    _srcAddress,
                    _dstAddress,
                    _payload
                )
            );
            address[] memory keepers = IBridgeData(dataAddr).getKeepers();
            uint256 n = keepers.length;
            require(
                Utils.verifySigs(hash, _sigs, keepers, n - (n - 1) / 3),
                "NO_SIG"
            );
        }

        IBridgeData(dataAddr).markDoneFromLogic(_srcChainID, _nonce);
        IBridgeProxy(proxyAddr).receivePayloadFromLogic(
            _srcChainID,
            _nonce,
            _srcAddress,
            _dstAddress,
            _payload,
            _gasLimit
        );
    }

    function updateKeepers(address[] calldata _newKeepers, bytes calldata _sigs)
        external
        override
    {
        require(_newKeepers.length > 0);

        {
            bytes32 hash = keccak256(
                abi.encodePacked("updateKeepers", _newKeepers)
            );
            address[] memory keepers = IBridgeData(dataAddr).getKeepers();
            uint256 n = keepers.length;
            require(
                Utils.verifySigs(hash, _sigs, keepers, n - (n - 1) / 3),
                "NO_SIG"
            );
        }

        IBridgeData(dataAddr).updateKeepersFromLogic(_newKeepers);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
