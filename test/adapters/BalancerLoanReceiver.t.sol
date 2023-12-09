pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {MockBalancerLoanReceiver} from "../mocks/MockBalancerLoanReceiver.sol";

/// @title Tests for BalancerLoanReceiver
/// @author Hilliam
/// @notice As BalancerLoanReceiver is an abstract class, we test `MockBalancerLoanReceiver`
contract BalancerLoanReceiverTest is DSTest {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address internal BALANCER_ADDRESS =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address internal USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    MockBalancerLoanReceiver mockBalancer;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        mockBalancer = new MockBalancerLoanReceiver(BALANCER_ADDRESS);
    }

    /*//////////////////////////////////////////////////////////////
                               _FLASHLOAN
    //////////////////////////////////////////////////////////////*/

    function testFail_flashLoanTokenZeroAddress() public {
        mockBalancer.mockFlashLoanAndRepay(address(0x0), 100);
    }

    function testSuccess_flashLoan() public {
        mockBalancer.mockFlashLoanAndRepay(WETH, 100);
    }

    function testSuccess_flashLoanAmountZero() public {
        mockBalancer.mockFlashLoanAndRepay(WETH, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        _FLASHLOANMULTIPLETOKENS
    //////////////////////////////////////////////////////////////*/

    function testFail_flashLoanMultipleTokensTokensNotArrangedAlphanumerically()
        public
    {
        address[] memory tokens = new address[](2);
        tokens[0] = WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        tokens[1] = USDC; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 52;

        mockBalancer.mockFlashLoanMultipleAndRepay(tokens, amounts);
    }

    function testSuccess_flashLoanMultipleTokens() public {
        address[] memory tokens = new address[](2);
        tokens[0] = USDC;
        tokens[1] = WETH;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 52;

        mockBalancer.mockFlashLoanMultipleAndRepay(tokens, amounts);
    }
}
