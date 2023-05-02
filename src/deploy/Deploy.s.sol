// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Script } from "forge-std/Script.sol";
import { FeeModule } from "src/FeeModule.sol";

/// @title Deploy
/// @notice Script to deploy the FeeModule
/// @author Polymarket
contract Deploy is Script {
    /// @notice Deploys the Adapter
    /// @param exchange - The CTFExchange address
    function deploy(address exchange) public returns (address module) {
        vm.startBroadcast();
        module = address(new FeeModule(exchange));
        vm.stopBroadcast();
    }
}
