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

    function withdrawERC20Fees(address token, uint256 amount) external;

    function withdrawERC1155Fees(address token, uint256 id, uint256 amount) external;
}
