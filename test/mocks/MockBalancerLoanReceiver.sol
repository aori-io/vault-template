pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {BalancerLoanReceiver} from "../../contracts/adapters/BalancerLoanReceiver.sol";

contract MockBalancerLoanReceiver is BalancerLoanReceiver {
    constructor(
        address _balancerAddress
    ) BalancerLoanReceiver(_balancerAddress) {}

    function mockFlashLoanAndRepay(address token, uint256 amount) public {
        _flashLoan(token, amount, "");
    }

    function mockFlashLoanMultipleAndRepay(
        address[] memory tokens,
        uint256[] memory amounts
    ) public {
        _flashLoanMultipleTokens(tokens, amounts, "");
    }

    function _flashLoanCallback(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal override {}
}
