// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "forge-std/Console.sol";
import {Vm} from "forge-std/Vm.sol";

import {FlashExecutor, FlashLoan, Instruction} from "../contracts/FlashExecutor.sol";
import {IWETH9} from "../contracts/interfaces/IWETH9.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MaliciousFlashLoaner} from "./mocks/MaliciousFlashLoaner.sol";

contract FlashExecutorTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    FlashExecutor internal executor;
    Instruction[] internal instructions;
    address[] internal tokens;
    IERC20[] internal ierc20_tokens;
    uint256[] internal amounts;

    address internal BALANCER_ADDRESS =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal aWETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        vm.startPrank(users[0]);
        executor = new FlashExecutor(users[0], BALANCER_ADDRESS);
        vm.stopPrank();
    }

    function testFail_callReceiveFlashLoanFromAddress() public {
        executor.receiveFlashLoan(ierc20_tokens, amounts, amounts, "");
    }

    function testFail_callFromMaliciousFlashLoaner() public {
        MaliciousFlashLoaner attacker = new MaliciousFlashLoaner();

        attacker.attack(address(executor), tokens, amounts);
    }

    function testFail_failingToRepayFlashLoan() public {
        // Setup
        address payable alice = users[0];
        // labels alice's address in call traces as "Alice [<address>]"
        vm.label(alice, "Alice");
        address payable bob = users[1];
        vm.label(bob, "Bob");

        // Payloads
        tokens.push(WETH);
        amounts.push(1000);
        FlashLoan memory loan = FlashLoan({tokens: tokens, amounts: amounts});

        Instruction memory sendToBob = Instruction({
            to: WETH,
            value: 1000,
            data: abi.encodeWithSignature("withdraw(uint256)", 1000)
        });
        instructions.push(sendToBob);

        vm.startPrank(alice);
        _tracedExecute(executor, loan, instructions, 0 ether);
        vm.stopPrank();
    }

    function testSuccess_emptyInstructionPayloadIsPerfectlyValid() public {
        // Setup
        address payable alice = users[0];
        // labels alice's address in call traces as "Alice [<address>]"
        vm.label(alice, "Alice");
        console.log("alice's address", alice);
        address payable bob = users[1];
        vm.label(bob, "Bob");

        // Payloads
        tokens.push(WETH);
        amounts.push(1 ether);
        FlashLoan memory loan = FlashLoan({tokens: tokens, amounts: amounts});

        vm.startPrank(alice);
        _tracedExecute(executor, loan, instructions, 0);
        vm.stopPrank();
    }

    function testFail_nonPermittedNoExecute() public {
        // Setup
        address payable alice = users[0];
        // labels alice's address in call traces as "Alice [<address>]"
        vm.label(alice, "Alice");
        console.log("alice's address", alice);
        address payable bob = users[1];
        vm.label(bob, "Bob");

        // Payloads
        tokens.push(WETH);
        amounts.push(1 ether);
        FlashLoan memory loan = FlashLoan({tokens: tokens, amounts: amounts});

        vm.startPrank(bob);
        _tracedExecute(executor, loan, instructions, 0);
        vm.stopPrank();
    }

    function testFail_nonPermittedNoWithdrawAll() public {
        address payable bob = users[1];
        vm.startPrank(bob);
        executor.withdrawAll(WETH, bob);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _tracedExecute(
        FlashExecutor executor,
        FlashLoan memory loan,
        Instruction[] memory instructions,
        uint256 value
    ) public {
        console.log("msg.value:", value);
        console.log("Flash loan: ");

        console.log("Instructions: ");
        for (uint256 i = 0; i < instructions.length; i++) {
            console.log("[ Instruction #", i, "]");
            console.log("to: ", instructions[i].to);
            console.log("value: ", instructions[i].value);
            console.log("data: ");
            console.logBytes(instructions[i].data);
        }

        console.log("Executing...");
        executor.flashExecute{value: value}(loan, instructions);
    }
}
