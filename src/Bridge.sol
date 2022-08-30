// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./libs/Utils.sol";
import "./interfaces/IReceiver.sol";

contract Bridge is Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

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

    uint256 public nonce;
    address[] private keepers;
    uint16 private immutable chainID;
    mapping(address => bool) public whiteListToContracMap;
    mapping(uint16 => mapping(uint256 => bool)) doneMap;

    constructor(uint16 _chainID, address[] memory _keepers) {
        keepers = _keepers;
        chainID = _chainID;
    }

    function keepersCount() external view returns (uint256) {
        return keepers.length;
    }

    function addOperator(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; ++i) {
            _grantRole(OPERATOR_ROLE, operators[i]);
        }
    }

    function send(
        uint16 _dstChainID,
        bytes calldata _destination,
        bytes calldata _payload
    ) external payable nonReentrant {
        emit Packet(msg.sender, nonce++, _dstChainID, _destination, _payload);
    }

    function receivePayload(
        uint16 _srcChainID,
        uint256 _nonce,
        bytes calldata _srcAddress,
        address _dstAddress,
        bytes calldata _payload,
        bytes calldata _sigs,
        uint256 _gasLimit
    ) external nonReentrant {
        require(
            owner() == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
            "NOT_ALLOWED"
        );

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    _srcChainID,
                    chainID,
                    _nonce,
                    _srcAddress,
                    _dstAddress,
                    _payload
                )
            );
            uint256 n = keepers.length;
            require(
                Utils.verifySigs(hash, _sigs, keepers, n - (n - 1) / 3),
                "NO_SIG"
            );
        }

        require(whiteListToContracMap[_dstAddress], "INVALID_TO");

        require(!doneMap[_srcChainID][_nonce], "ALREADY_DONE");
        doneMap[_srcChainID][_nonce] = true;

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
