// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order } from "../libraries/Structs.sol";

interface IExchange {
    function getCollateral() external view returns (address);

    function getCtf() external view returns (address);

    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external;
}
