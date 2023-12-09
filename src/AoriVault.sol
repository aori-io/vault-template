// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IAoriProtocol } from "aori-contracts/src/IAoriProtocol.sol";
import { AoriProtocol } from "aori-contracts/src/AoriProtocol.sol";
import { IERC1271 } from "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

contract AoriVault is IERC1271 {

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public aoriProtocol;

    mapping (address => bool) public managers;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        address _aoriProtocol
    ) {
        owner = _owner;
        managers[owner] = true;
        aoriProtocol = _aoriProtocol;
    }

    /*//////////////////////////////////////////////////////////////
                                 CALLS
    //////////////////////////////////////////////////////////////*/

    function makeTrade(
        AoriProtocol.MatchingDetails memory matching,
        AoriProtocol.Signature memory serverSignature
    ) external {
        require(managers[msg.sender], "Only a manager can call this function");
        IAoriProtocol(aoriProtocol).settleOrders(matching, serverSignature);
    }

    function makeExternalCall(address to, uint256 value, bytes memory data) external returns (bool, bytes memory) {
        require(managers[msg.sender], "Only a manager can call this function");
        (bool success, bytes memory returnedData) = (to).call{value: value}(data);
        return (success, returnedData);
    }

    /*//////////////////////////////////////////////////////////////
                                EIP-1271
    //////////////////////////////////////////////////////////////*/

    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
        require(_signature.length == 65);

        // Deconstruct the signature into v, r, s
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(_signature, 32))
            // second 32 bytes.
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(_signature, 96)))
        }

        address ethSignSigner = ecrecover(_hash, v, r, s);

        // EIP1271 - dangerous if the eip151-eip1271 pairing can be found
        address eip1271Signer = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _hash
                )
            ), v, r, s);

        // check if the signature comes from a valid manager
        if (managers[ethSignSigner] || managers[eip1271Signer]) {
            return ERC1271_MAGICVALUE;
        }

        return 0x0;
    }

    /*//////////////////////////////////////////////////////////////
                               MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setManager(address _manager, bool _isManager) external {
        require(owner == msg.sender, "Only owner can call this function");
        managers[_manager] = _isManager;
    }

    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/

    receive () external payable {}
    fallback () external payable {}
}