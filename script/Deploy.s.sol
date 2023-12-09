// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AoriVault.sol";
import {ICREATE3Factory} from "create3-factory/src/ICREATE3Factory.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployerAddress = vm.addr(deployerPrivateKey);
        address create3FactoryAddress = vm.envAddress("CREATE3FACTORY_ADDRESS");
        address aoriProtocolAddress = vm.envAddress("AORIPROTOCOL_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        ICREATE3Factory(create3FactoryAddress).deploy(
            keccak256(bytes("if youre reading this, trade on aori thx")),
            abi.encodePacked(
                type(AoriVault).creationCode,
                abi.encode(deployerAddress, aoriProtocolAddress)
            )
        );

        vm.stopBroadcast();
    }
}
