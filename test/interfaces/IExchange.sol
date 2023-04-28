// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order } from "src/libraries/Structs.sol";

interface IExchange {
    function registerToken(uint256 token, uint256 complement, bytes32 conditionId) external;

    function addOperator(address) external;

    function addAdmin(address) external;
    
    function getCollateral() external view returns (address);

    function getCtf() external view returns (address);

    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external;

}