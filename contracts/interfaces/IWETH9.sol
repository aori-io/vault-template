pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
