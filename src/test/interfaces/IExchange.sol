// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order, OrderStatus } from "src/libraries/Structs.sol";

interface IExchangeEE {
    /// @notice Emitted when an order is filled
    event OrderFilled(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled,
        uint256 fee
    );

    /// @notice Emitted when a set of orders is matched
    event OrdersMatched(
        bytes32 indexed takerOrderHash,
        address indexed takerOrderMaker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );
}

interface IExchange is IExchangeEE {
    function registerToken(uint256 token, uint256 complement, bytes32 conditionId) external;

    function addOperator(address) external;

    function addAdmin(address) external;

    function getCollateral() external view returns (address);

    function getCtf() external view returns (address);

    function hashOrder(Order memory order) external view returns (bytes32);

    function getOrderStatus(bytes32 orderHash) external view returns (OrderStatus memory);

    function getMaxFeeRate() external view returns (uint256);

    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external;
}
