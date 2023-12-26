pragma solidity 0.8.19;

struct FlashLoan {
    address[] tokens;
    uint256[] amounts;
}

struct Instruction {
    address to;
    uint256 value;
    bytes data;
}

interface IFlashExecutor {

    function execute(Instruction[] calldata instructions) external payable;

    function flashExecute(
        FlashLoan calldata loan,
        Instruction[] calldata instructions
    ) external payable;

    function withdrawAll(address token, address recipient) external;

    function setManager(address _manager, bool _isManager) external;
}