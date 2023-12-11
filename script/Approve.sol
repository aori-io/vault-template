// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ICREATE3Factory} from "create3-factory/src/ICREATE3Factory.sol";

interface IAoriVault {
    function setManager(address _manager, bool _isManager) external;
}

contract ApproveScript is Script {
    function run() external {
        uint256 ownerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address ownerAddress = vm.addr(ownerPrivateKey);
        address newManager = vm.envAddress("NEW_MANAGER_ADDRESS");
        address aoriVaultContract = vm.envAddress("VAULT_ADDRESS");

        vm.startBroadcast(ownerPrivateKey);
        IAoriVault(aoriVaultContract).setManager(newManager, true);
        vm.stopBroadcast();
    }
}
