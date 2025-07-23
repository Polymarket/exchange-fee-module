// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { FeeModule } from "src/FeeModule.sol";

/// @title DeployFeeModule
/// @notice Script to deploy the FeeModule
/// @author Polymarket
contract DeployFeeModule is Script {
    /// @notice Deploys the FeeModule
    /// @param admin    - The admin
    /// @param exchange - The CTFExchange address
    function run(address admin, address exchange) public returns (address module) {
        vm.startBroadcast();

        FeeModule feeModule = new FeeModule(exchange);

        // Add admin auth to the Admin address
        feeModule.addAdmin(admin);

        // revoke deployer's auth
        feeModule.renounceAdmin();

        module = address(feeModule);

        vm.stopBroadcast();

        if (!_verifyStatePostDeployment(admin, exchange, module)) revert("state verification post deployment failed");
    }

    function _verifyStatePostDeployment(address admin, address exchange, address feeModule)
        internal
        view
        returns (bool)
    {
        FeeModule module = FeeModule(feeModule);

        if (module.isAdmin(msg.sender)) revert("Deployer admin not renounced");
        if (!module.isAdmin(admin)) revert("FeeModule admin not set");
        if (address(module.exchange()) != exchange) revert("Unexpected exchange set on the FeeModule");

        return true;
    }
}
