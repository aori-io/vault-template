// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {AdvancedOrder, Fulfillment} from "seaport-types/src/lib/ConsiderationStructs.sol";

interface IOrderProtocol {
    
    function settleOrders(
        MatchingDetails memory matching,
        Signature memory serverSignature
    ) external;

    struct MatchingDetails {
        AdvancedOrder[] makerOrders;
        AdvancedOrder takerOrder;
        Fulfillment[] fulfillments;
        uint256 blockDeadline;
        uint256 chainId;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
