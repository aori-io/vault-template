pragma solidity >=0.8.17;

import {DSTest} from "ds-test/test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { SeaportInterface } from "seaport-types/src/interfaces/SeaportInterface.sol";
import { ConsiderationInterface } from "seaport-types/src/interfaces/ConsiderationInterface.sol";
import { AdvancedOrder, CriteriaResolver, Fulfillment, FulfillmentComponent, OrderParameters, OfferItem, ConsiderationItem, CriteriaResolver, ItemType, OrderComponents } from "seaport-types/src/lib/ConsiderationStructs.sol";
import { OrderType, Side } from "seaport-types/src/lib/ConsiderationEnums.sol";

import { SimpleToken } from "./mocks/SimpleToken.sol";
import { OrderHasher } from "./utils/OrderHasher.sol";
import { AoriVault } from "../contracts/AoriVault.sol";
import { Instruction } from "../contracts/FlashExecutor.sol";
import { IAoriProtocol } from "aori-contracts/src/IAoriProtocol.sol";
import { AoriProtocol } from "aori-contracts/src/AoriProtocol.sol";

contract AoriVaultTest is DSTest {
    Vm internal vm = Vm(HEVM_ADDRESS);
    address constant SEAPORT_ADDRESS = 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC;
    address constant BALANCER_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    AoriProtocol internal aoriProtocol;
    AoriVault internal aoriVault;

    bytes32 internal _OFFER_ITEM_TYPEHASH;
    bytes32 internal _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal _ORDER_TYPEHASH;

    /*//////////////////////////////////////////////////////////////
                                 USERS
    //////////////////////////////////////////////////////////////*/
    
    uint256 SERVER_PRIVATE_KEY = 1;
    uint256 FAKE_SERVER_PRIVATE_KEY = 2;
    uint256 MAKER_PRIVATE_KEY = 3;
    uint256 FAKE_MAKER_PRIVATE_KEY = 4;
    uint256 TAKER_PRIVATE_KEY = 5;
    uint256 FAKE_TAKER_PRIVATE_KEY = 6;
    uint256 SEARCHER_PRIVATE_KEY = 7;

    address SERVER_WALLET = address(vm.addr(SERVER_PRIVATE_KEY));
    address FAKE_SERVER_WALLET = address(vm.addr(FAKE_SERVER_PRIVATE_KEY));
    address MAKER_WALLET = address(vm.addr(MAKER_PRIVATE_KEY));
    address FAKE_MAKER_WALLET = address(vm.addr(FAKE_MAKER_PRIVATE_KEY));
    address TAKER_WALLET = address(vm.addr(TAKER_PRIVATE_KEY));
    address FAKE_TAKER_WALLET = address(vm.addr(FAKE_TAKER_PRIVATE_KEY));
    address SEARCHER_WALLET = address(vm.addr(SEARCHER_PRIVATE_KEY));

    /*//////////////////////////////////////////////////////////////
                                 ASSETS
    //////////////////////////////////////////////////////////////*/

    SimpleToken tokenA = new SimpleToken();
    SimpleToken tokenB = new SimpleToken();

    OfferItem[] internal offerItems;
    ConsiderationItem[] internal considerationItems;
    AdvancedOrder[] internal advancedOrders;

    bytes32[] internal criteriaProofs;
    CriteriaResolver[] internal criteriaResolvers;
    FulfillmentComponent[] internal offerFulfillmentComponents;
    FulfillmentComponent[] internal considerationFulfillmentComponents;
    Fulfillment[] internal fulfillments;

    OrderHasher internal orderHasher;

    Instruction[] internal instructions;

    function setUp() public {
        aoriProtocol = new AoriProtocol(SERVER_WALLET, SEAPORT_ADDRESS);

        vm.prank(MAKER_WALLET);
        aoriVault = new AoriVault(MAKER_WALLET, address(aoriProtocol), BALANCER_ADDRESS);

        vm.label(address(aoriProtocol), "Order Protocol");
        vm.label(address(aoriVault), "Order Vault");

        vm.label(SERVER_WALLET, "Server Wallet");
        vm.label(FAKE_SERVER_WALLET, "Fake Server Wallet");
        vm.label(MAKER_WALLET, "Maker Wallet");
        vm.label(FAKE_MAKER_WALLET, "Fake Maker Wallet");
        vm.label(TAKER_WALLET, "Taker Wallet");
        vm.label(FAKE_TAKER_WALLET, "Fake Taker Wallet");

        vm.label(address(tokenA), "TokenA");
        vm.label(address(tokenB), "TokenB");

        vm.deal(MAKER_WALLET, 100 ether);

        orderHasher = new OrderHasher();
    }

    /*//////////////////////////////////////////////////////////////
                               MAKETRADE
    //////////////////////////////////////////////////////////////*/

    function test_failMakeTradeNotOwner() public {
        
        /*//////////////////////////////////////////////////////////////
                                    PARAMS
        //////////////////////////////////////////////////////////////*/

        AoriProtocol.MatchingDetails memory matching;
        AoriProtocol.Signature memory serverSignature;

        /*//////////////////////////////////////////////////////////////
                                    EXECUTE
        //////////////////////////////////////////////////////////////*/

        vm.startPrank(FAKE_SERVER_WALLET);
        vm.expectRevert("Only owner can execute");

        Instruction memory instruction = Instruction({
            to: address(aoriVault),
            value: 0,
            data: "0x"
        });
        instructions.push(instruction);

        aoriVault.execute(instructions);
        vm.stopPrank();
    }

    function test_failMakeTradeForgedSignature() public {

        /*//////////////////////////////////////////////////////////////
                                ORDER CREATION
        //////////////////////////////////////////////////////////////*/

        offerItems.push(_createBaseOfferItemERC20(address(tokenA), 1 ether));
        considerationItems.push(_createBaseConsiderationItemERC20(address(tokenB), 1 ether, address(aoriVault)));

        OrderParameters memory parameters = _createBaseOrderParameters(address(aoriVault), address(aoriProtocol));
        OrderComponents memory makerOrderComponents = _getOrderComponents(parameters);
        
        bytes memory makerSignature = this._signOrder(
            FAKE_MAKER_PRIVATE_KEY,
            orderHasher._getOrderHash(makerOrderComponents)
        );

        AdvancedOrder memory order1 = AdvancedOrder({
            parameters: parameters,
            numerator: 10,
            denominator: 10,
            signature: makerSignature,
            extraData: "0x"
        });
        advancedOrders.push(order1);

        /*//////////////////////////////////////////////////////////////
                                  TAKER ORDER
        //////////////////////////////////////////////////////////////*/

        offerItems.push(_createBaseOfferItemERC20(address(tokenB), 1 ether));
        considerationItems.push(_createBaseConsiderationItemERC20(address(tokenA), 1 ether, TAKER_WALLET));

        OrderParameters memory takerParameters = _createBaseOrderParameters(TAKER_WALLET, address(aoriProtocol));
        OrderComponents memory takerOrderComponents = _getOrderComponents(takerParameters);
        
        bytes memory takerSignature = this._signOrder(
            TAKER_PRIVATE_KEY,
            orderHasher._getOrderHash(takerOrderComponents)
        );

        AdvancedOrder memory takerOrder = AdvancedOrder({
            parameters: takerParameters,
            numerator: 10,
            denominator: 10,
            signature: takerSignature,
            extraData: "0x"
        });

        /*//////////////////////////////////////////////////////////////
                                FULFILLMENTS
        //////////////////////////////////////////////////////////////*/

        offerFulfillmentComponents.push(FulfillmentComponent(0, 0));
        considerationFulfillmentComponents.push(FulfillmentComponent(1, 0));

        Fulfillment memory fulfillment = Fulfillment(
            offerFulfillmentComponents,
            considerationFulfillmentComponents
        );

         Fulfillment memory fulfillment2 = Fulfillment(
            new FulfillmentComponent[](1),
            new FulfillmentComponent[](1)
        );
        fulfillment2.offerComponents[0] = FulfillmentComponent(1, 0);
        fulfillment2.considerationComponents[0] = FulfillmentComponent(0, 0);

        fulfillments.push(fulfillment);
        fulfillments.push(fulfillment2);

        /*//////////////////////////////////////////////////////////////
                                SERVER SIGNATURE
        //////////////////////////////////////////////////////////////*/

        bytes32 matchingHash = keccak256(
            abi.encode(
                advancedOrders,
                takerOrder,
                fulfillments,
                block.number,
                block.chainid
            )
        );

        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(
            SERVER_PRIVATE_KEY,
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    matchingHash
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                                    SETTLEMENT
        //////////////////////////////////////////////////////////////*/

        // Have the manager approve transfer approval of tokenA by Seaport contract
        vm.startPrank(MAKER_WALLET);
        Instruction memory instruction = Instruction({
            to: address(tokenA),
            value: 0,
            data: abi.encodeWithSignature("approve(address,uint256)", SEAPORT_ADDRESS, 2 ** 256 - 1)
        });
        instructions.push(instruction);

        aoriVault.execute(instructions);
        instructions.pop();
        vm.stopPrank();

        // Mint some tokens for the AoriVault
        vm.prank(address(aoriVault));
        tokenA.mint(1 ether);

        vm.startPrank(TAKER_WALLET);
        IERC20(address(tokenB)).approve(SEAPORT_ADDRESS, 2 ** 256 - 1);
        tokenB.mint(1 ether);
        vm.stopPrank();

        vm.startPrank(MAKER_WALLET);

        Instruction memory takerInstruction = Instruction({
            to: address(aoriProtocol),
            value: 0,
            data: abi.encodeWithSelector(AoriProtocol.settleOrders.selector, AoriProtocol.MatchingDetails({
                makerOrders: advancedOrders,
                takerOrder: takerOrder,
                fulfillments: fulfillments,
                blockDeadline: block.number,
                chainId: block.chainid
            }), AoriProtocol.Signature({
                v: serverV,
                r: serverR,
                s: serverS
            }))
        });

        instructions.push(takerInstruction);
        vm.expectRevert();
        aoriVault.execute(instructions);
        instructions.pop();

        vm.stopPrank();
    }

    function test_successMakeTrade() public {

        /*//////////////////////////////////////////////////////////////
                                ORDER CREATION
        //////////////////////////////////////////////////////////////*/

        offerItems.push(_createBaseOfferItemERC20(address(tokenA), 1 ether));
        considerationItems.push(_createBaseConsiderationItemERC20(address(tokenB), 1 ether, address(aoriVault)));

        OrderParameters memory parameters = _createBaseOrderParameters(address(aoriVault), address(aoriProtocol));
        OrderComponents memory makerOrderComponents = _getOrderComponents(parameters);
        
        bytes memory makerSignature = this._signOrder(
            MAKER_PRIVATE_KEY,
            orderHasher._getOrderHash(makerOrderComponents)
        );

        AdvancedOrder memory order1 = AdvancedOrder({
            parameters: parameters,
            numerator: 10,
            denominator: 10,
            signature: makerSignature,
            extraData: "0x"
        });
        advancedOrders.push(order1);

        /*//////////////////////////////////////////////////////////////
                                  TAKER ORDER
        //////////////////////////////////////////////////////////////*/

        offerItems.push(_createBaseOfferItemERC20(address(tokenB), 1 ether));
        considerationItems.push(_createBaseConsiderationItemERC20(address(tokenA), 1 ether, TAKER_WALLET));

        OrderParameters memory takerParameters = _createBaseOrderParameters(TAKER_WALLET, address(aoriProtocol));
        OrderComponents memory takerOrderComponents = _getOrderComponents(takerParameters);
        
        bytes memory takerSignature = this._signOrder(
            TAKER_PRIVATE_KEY,
            orderHasher._getOrderHash(takerOrderComponents)
        );

        AdvancedOrder memory takerOrder = AdvancedOrder({
            parameters: takerParameters,
            numerator: 10,
            denominator: 10,
            signature: takerSignature,
            extraData: "0x"
        });

        /*//////////////////////////////////////////////////////////////
                                FULFILLMENTS
        //////////////////////////////////////////////////////////////*/

        offerFulfillmentComponents.push(FulfillmentComponent(0, 0));
        considerationFulfillmentComponents.push(FulfillmentComponent(1, 0));

        Fulfillment memory fulfillment = Fulfillment(
            offerFulfillmentComponents,
            considerationFulfillmentComponents
        );

         Fulfillment memory fulfillment2 = Fulfillment(
            new FulfillmentComponent[](1),
            new FulfillmentComponent[](1)
        );
        fulfillment2.offerComponents[0] = FulfillmentComponent(1, 0);
        fulfillment2.considerationComponents[0] = FulfillmentComponent(0, 0);

        fulfillments.push(fulfillment);
        fulfillments.push(fulfillment2);

        /*//////////////////////////////////////////////////////////////
                                SERVER SIGNATURE
        //////////////////////////////////////////////////////////////*/

        bytes32 matchingHash = keccak256(
            abi.encode(
                advancedOrders,
                takerOrder,
                fulfillments,
                block.number,
                block.chainid
            )
        );

        (uint8 serverV, bytes32 serverR, bytes32 serverS) = vm.sign(
            SERVER_PRIVATE_KEY,
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    matchingHash
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                                    SETTLEMENT
        //////////////////////////////////////////////////////////////*/

        // Have the manager approve transfer approval of tokenA by Seaport contract
        vm.startPrank(MAKER_WALLET);
        Instruction memory instruction = Instruction({
            to: address(tokenA),
            value: 0,
            data: abi.encodeWithSignature("approve(address,uint256)", SEAPORT_ADDRESS, 2 ** 256 - 1)
        });
        instructions.push(instruction);

        aoriVault.execute(instructions);
        instructions.pop();
        vm.stopPrank();

        // Mint some tokens for the AoriVault
        vm.prank(address(aoriVault));
        tokenA.mint(1 ether);

        vm.startPrank(TAKER_WALLET);
        IERC20(address(tokenB)).approve(SEAPORT_ADDRESS, 2 ** 256 - 1);
        tokenB.mint(1 ether);
        vm.stopPrank();

        vm.startPrank(MAKER_WALLET);
        Instruction memory takerInstruction = Instruction({
            to: address(aoriProtocol),
            value: 0,
            data: abi.encodeWithSelector(AoriProtocol.settleOrders.selector, AoriProtocol.MatchingDetails({
                makerOrders: advancedOrders,
                takerOrder: takerOrder,
                fulfillments: fulfillments,
                blockDeadline: block.number,
                chainId: block.chainid
            }), AoriProtocol.Signature({
                v: serverV,
                r: serverR,
                s: serverS
            }))
        });

        instructions.push(takerInstruction);
        aoriVault.execute(instructions);
        instructions.pop();
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            MAKEEXTERNALCALL
    //////////////////////////////////////////////////////////////*/

    function test_failMakeExternalCallNotOwner() public {
        vm.startPrank(FAKE_SERVER_WALLET);
        vm.expectRevert("Only owner can execute");

        Instruction memory instruction = Instruction({
            to: FAKE_MAKER_WALLET,
            value: 10 ether,
            data: "0x"
        });
        instructions.push(instruction);
        aoriVault.execute(instructions);
        vm.stopPrank();
    }

    function test_successMakeExternalCall() public {
        vm.startPrank(MAKER_WALLET);
        Instruction memory instruction = Instruction({
            to: TAKER_WALLET,
            value: 0 ether,
            data: "0x"
        });
        instructions.push(instruction);
        aoriVault.execute(instructions);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               SETMANAGER
    //////////////////////////////////////////////////////////////*/

    function test_failSetManagerNotOwner() public {
        vm.startPrank(FAKE_MAKER_WALLET);
        vm.expectRevert("Only owner can call this function");
        aoriVault.setManager(FAKE_MAKER_WALLET, true);
        vm.stopPrank();
    }

    function test_successSetManager() public {
        vm.startPrank(MAKER_WALLET);
        aoriVault.setManager(MAKER_WALLET, true);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                FALLBACK
    //////////////////////////////////////////////////////////////*/

    function test_successSendETH() public {
        vm.deal(MAKER_WALLET, 10 ether);
        vm.startPrank(MAKER_WALLET);
        (bool success, ) = payable(address(aoriVault)).call{value: 1 ether}("");
        require(success);
        vm.stopPrank();
    }

    function test_successERC20() public {
        vm.startPrank(MAKER_WALLET);
        tokenA.mint(10 ether);
        tokenA.transfer(address(aoriVault), 10 ether);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createBaseOfferItemERC20(address _tokenAddress, uint256 _amount) internal pure returns (OfferItem memory) {
        return OfferItem({
            itemType: ItemType.ERC20,
            token: _tokenAddress,
            identifierOrCriteria: 0,
            startAmount: _amount,
            endAmount: _amount
        });
    }

    function _createBaseConsiderationItemERC20(address _tokenAddress, uint256 _amount, address _recipient) internal pure returns (ConsiderationItem memory) {
        return ConsiderationItem({
            itemType: ItemType.ERC20,
            token: _tokenAddress,
            identifierOrCriteria: 0,
            startAmount: _amount,
            endAmount: _amount,
            recipient: payable(_recipient)
        });
    }

    function _createBaseOrderParameters(address _offerer, address _zone) internal returns (OrderParameters memory) {
        OrderParameters memory parameters = OrderParameters({
            offerer: _offerer,
            zone: _zone,
            offer: offerItems,
            consideration: considerationItems,
            orderType: OrderType.PARTIAL_RESTRICTED,
            startTime: 0,
            endTime: block.timestamp * 2,
            zoneHash: bytes32(0),
            salt: 0,
            conduitKey: bytes32(0),
            totalOriginalConsiderationItems: considerationItems.length
        });

        while (offerItems.length > 0) {
            offerItems.pop();
        }

        while (considerationItems.length > 0) {
            considerationItems.pop();
        }

        return parameters;
    }

    /**
     * @dev return OrderComponents for a given OrderParameters and offerer
     *      counter
     */
    function _getOrderComponents(
        OrderParameters memory parameters
    ) internal view returns (OrderComponents memory) {
        return
            OrderComponents(
                parameters.offerer,
                parameters.zone,
                parameters.offer,
                parameters.consideration,
                parameters.orderType,
                parameters.startTime,
                parameters.endTime,
                parameters.zoneHash,
                parameters.salt,
                parameters.conduitKey,
                SeaportInterface(SEAPORT_ADDRESS).getCounter(parameters.offerer) // counter
            );
    }

    function _signOrder(
        uint256 _pkOfSigner,
        bytes32 _orderHash
    ) external view returns (bytes memory) {
        (bytes32 r, bytes32 s, uint8 v) = getSignatureComponents(
            ConsiderationInterface(SEAPORT_ADDRESS), // seaport address
            _pkOfSigner,
            _orderHash
        );
        return abi.encodePacked(r, s, v);
    }

    function getSignatureComponents(
        ConsiderationInterface _consideration,
        uint256 _pkOfSigner,
        bytes32 _orderHash
    ) internal view returns (bytes32, bytes32, uint8) {
        (, bytes32 domainSeparator, ) = _consideration.information();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _pkOfSigner,
            keccak256(
                abi.encodePacked(bytes2(0x1901), domainSeparator, _orderHash)
            )
        );
        return (r, s, v);
    }
}