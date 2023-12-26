pragma solidity 0.8.19;

import {IFlashExecutor} from "./IFlashExecutor.sol";

interface IAoriVault is IFlashExecutor {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
}