// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SeaportInterface} from "seaport-types/src/interfaces/SeaportInterface.sol";
import {AdvancedOrder, CriteriaResolver, Fulfillment, OrderParameters, OrderComponents} from "seaport-types/src/lib/ConsiderationStructs.sol";
import { IOrderProtocol } from "./IOrderProtocol.sol";
import { ERC4626, IERC20, ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

contract OrderVault is ERC4626 {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public orderProtocol;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _orderProtocol,
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) {
        owner = msg.sender;
        orderProtocol = _orderProtocol;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeTrade(
        IOrderProtocol.MatchingDetails memory matching,
        IOrderProtocol.Signature memory serverSignature
    ) external {
        require(owner == msg.sender, "Only owner can call this function");
        IOrderProtocol(orderProtocol).settleOrders(matching, serverSignature);
    }

    function makeExternalCall(address to, uint256 value, bytes memory data) external returns (bool, bytes memory) {
        require(owner == msg.sender, "Only owner can call this function");
        (bool success, bytes memory returnedData) = (to).call{value: value}(data);
        return (success, returnedData);
    }

    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/

    fallback () external {}
}