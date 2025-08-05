// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { NegRiskFeeModule } from "src/NegRiskFeeModule.sol";

/// @title DeployNegRiskFeeModule
/// @notice Script to deploy the NegRiskFeeModule
/// @author Polymarket
contract DeployNegRiskFeeModule is Script {
    /// @notice Deploys the FeeModule
    /// @param admin                - The admin
    /// @param negRiskCtfExchange   - The NegRisk CTF Exchange address
    /// @param negRiskAdapter       - The NegRisk adapter address
    /// @param ctf                  - The Conditional Tokens Framework address
    function run(address admin, address negRiskCtfExchange, address negRiskAdapter, address ctf)
        public
        returns (address module)
    {
        vm.startBroadcast();

        NegRiskFeeModule nrFeeModule = new NegRiskFeeModule(negRiskCtfExchange, negRiskAdapter, ctf);

        // Add admin auth to the Admin address
        nrFeeModule.addAdmin(admin);

        // revoke deployer's auth
        nrFeeModule.renounceAdmin();

        module = address(nrFeeModule);

        vm.stopBroadcast();

        if (!_verifyStatePostDeployment(admin, negRiskCtfExchange, module)) {
            revert("state verification post deployment failed");
        }
    }

    function _verifyStatePostDeployment(address admin, address exchange, address feeModule)
        internal
        view
        returns (bool)
    {
        NegRiskFeeModule module = NegRiskFeeModule(feeModule);

        if (module.isAdmin(msg.sender)) revert("Deployer admin not renounced");
        if (!module.isAdmin(admin)) revert("NegRiskFeeModule admin not set");
        if (address(module.exchange()) != exchange) revert("Unexpected exchange set on the NegRiskFeeModule");

        return true;
    }
}
