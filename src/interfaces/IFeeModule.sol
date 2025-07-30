// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Order } from "../libraries/Structs.sol";

interface IFeeModuleEE {
    /// @notice Emitted when fees are withdrawn from the FeeModule
    event FeeWithdrawn(address token, address to, uint256 id, uint256 amount);

    /// @notice Emitted when fees are refunded to the order maker
    event FeeRefunded(
        bytes32 indexed orderHash, address indexed to, uint256 id, uint256 refund, uint256 indexed feeCharged
    );
}

interface IFeeModule is IFeeModuleEE {
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 takerFeeAmount,
        uint256[] memory makerFeeAmount
    ) external;

    function withdrawFees(address to, uint256 id, uint256 amount) external;
}
