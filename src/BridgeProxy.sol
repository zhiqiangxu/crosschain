// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "./libs/Utils.sol";
import "./interfaces/IReceiver.sol";

contract BridgeProxy is Ownable, ReentrancyGuard {
    event Packet(
        address sender,
        uint256 nonce,
        uint16 dstChainID,
        bytes destination,
        bytes payload
    );
    event StoredPacket(
        uint16 srcChainID,
        bytes srcAddress,
        address dstAddress,
        uint256 nonce,
        bytes payload
    );

    address public logic;
    uint256 public nonce;

    function upgradeLogic(address _logic) external onlyOwner {
        logic = _logic;
    }

    function sendFromLogic(
        address sender,
        uint16 _dstChainID,
        bytes calldata _destination,
        bytes calldata _payload
    ) external nonReentrant {
        require(msg.sender == logic, "INVALID_SENDER");

        emit Packet(sender, nonce++, _dstChainID, _destination, _payload);
    }

    function receivePayloadFromLogic(
        uint16 _srcChainID,
        uint256 _nonce,
        bytes calldata _srcAddress,
        address _dstAddress,
        bytes calldata _payload,
        uint256 _gasLimit
    ) external nonReentrant {
        require(msg.sender == logic, "INVALID_SENDER");

        require(
            IReceiver(_dstAddress).onReceive{gas: _gasLimit}(
                _srcChainID,
                _srcAddress,
                _nonce,
                _payload
            ),
            "ON_RECV"
        );

        emit StoredPacket(
            _srcChainID,
            _srcAddress,
            _dstAddress,
            _nonce,
            _payload
        );
    }
}
