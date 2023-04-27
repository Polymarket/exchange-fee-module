// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order } from "../libraries/OrderStructs.sol";

interface IFeeModule {
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external;
}
