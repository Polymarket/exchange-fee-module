// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { FeeModule } from "src/FeeModule.sol";

/// @title DeployFeeModule
/// @notice Script to deploy the FeeModule
/// @author Polymarket
contract DeployFeeModule is Script {
    /// @notice Deploys the FeeModule
    /// @param exchange - The CTFExchange address
    function deploy(address exchange) public returns (address module) {
        vm.startBroadcast();
        module = address(new FeeModule(exchange));
        vm.stopBroadcast();
    }
}
