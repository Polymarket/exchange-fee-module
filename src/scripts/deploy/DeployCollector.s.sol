// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { Collector } from "src/Collector.sol";

/// @title DeployCollector
/// @notice Script to deploy the Collector
/// @author Polymarket
contract DeployCollector is Script {
    /// @notice Deploys the Collector
    /// @param admin    - The admin
    /// @param feeModule - The fee module address
    function run(address admin, address feeModule) public returns (address collector) {
        vm.startBroadcast();

        Collector col = new Collector(feeModule);

        // Add admin auth to the Admin address
        col.addAdmin(admin);

        // revoke deployer's auth
        col.renounceAdmin();

        collector = address(col);

        vm.stopBroadcast();

        if (!_verifyStatePostDeployment(admin, feeModule, collector)) revert("state verification post deployment failed");
    }

    function _verifyStatePostDeployment(address admin, address feeModule, address collector)
        internal
        view
        returns (bool)
    {
        Collector col = Collector(collector);

        if (col.isAdmin(msg.sender)) revert("Deployer admin not renounced");
        if (!col.isAdmin(admin)) revert("Collector admin not set");
        if (address(col.feeModule()) != feeModule) revert("Unexpected feeModule set on the Collector");

        return true;
    }
}
