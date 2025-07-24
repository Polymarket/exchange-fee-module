// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC1155TokenReceiver } from "lib/solmate/src/tokens/ERC1155.sol";

import { Auth } from "./mixins/Auth.sol";
import { Transfers } from "./mixins/Transfers.sol";

import { IExchange } from "./interfaces/IExchange.sol";
import { IFeeModule } from "./interfaces/IFeeModule.sol";

import { Order, Side, Trader } from "./libraries/Structs.sol";
import { CalculatorHelper } from "./libraries/CalculatorHelper.sol";

/// @title Polymarket CTF Fee Module
/// @notice Proxies the CTFExchange contract and refunds orders
/// @author Jon Amenechi (jon@polymarket.com)
contract FeeModule is IFeeModule, Auth, Transfers, ERC1155TokenReceiver {
    /// @notice The Exchange contract
    IExchange public immutable exchange;

    /// @notice The Collateral token
    address public immutable collateral;

    /// @notice The CTF contract
    address public immutable ctf;

    constructor(address _exchange) {
        exchange = IExchange(_exchange);
        collateral = exchange.getCollateral();
        ctf = exchange.getCtf();
    }

    /// @notice Matches a taker order against a list of maker orders, refunding maker order fees if necessary
    /// @param takerOrder       - The active order to be matched
    /// @param makerOrders      - The array of maker orders to be matched against the active order
    /// @param takerFillAmount  - The amount to fill on the taker order, always in terms of the maker amount
    /// @param makerFillAmounts - The array of amounts to fill on the maker orders, always in terms of the maker amount
    /// @param takerFeeAmount   - The fee to be charged to the taker
    /// @param makerFeeAmounts  - The fee to be charged to the maker orders
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 takerFeeAmount,
        uint256[] memory makerFeeAmounts
    ) external onlyAdmin {
        // Match the orders on the exchange
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, makerFillAmounts);

        // Refund taker fees
        _refundTakerFees(takerOrder, takerFillAmount, takerFeeAmount);

        // Refund maker fees
        _refundMakerFees(makerOrders, makerFillAmounts, makerFeeAmounts);
    }

    /// @notice Withdraw collected fees
    /// @param id       - The tokenID to be withdrawn. If 0, will be the collateral token.
    /// @param amount   - The amount to be withdrawn
    function withdrawFees(address to, uint256 id, uint256 amount) external onlyAdmin {
        address token = id == 0 ? collateral : ctf;
        _transfer(token, address(this), to, id, amount);
        emit FeeWithdrawn(token, to, id, amount);
    }

    /// @notice Refund fees for the taker order
    /// @param order        - The taker order
    /// @param fillAmount   - The fill amount for the the taker order
    /// @param feeAmount    - The fee amount for the taker order
    function _refundTakerFees(Order memory order, uint256 fillAmount, uint256 feeAmount) internal {
        _refundFee(order, fillAmount, feeAmount, Trader.TAKER);
    }

    /// @notice Refund fees for a set of maker orders
    /// @param orders       - The array of maker orders
    /// @param fillAmounts  - The array of fill amounts for the maker orders
    /// @param feeAmounts   - The array of fee amounts charged to the maker orders
    function _refundMakerFees(Order[] memory orders, uint256[] memory fillAmounts, uint256[] memory feeAmounts)
        internal
    {
        for (uint256 i = 0; i < orders.length; ++i) {
            _refundFee(orders[i], fillAmounts[i], feeAmounts[i], Trader.MAKER);
        }
    }

    /// @notice Refund the fee for an order, if necessary
    /// @param order        - The order
    /// @param fillAmount   - The fill amount for the order
    /// @param feeAmount    - The fee amount for the order, chosen by the operator
    /// @param trader       - An enum denoting whether the Trader is a Maker or a Taker
    function _refundFee(Order memory order, uint256 fillAmount, uint256 feeAmount, Trader trader) internal {
        // Calculate refund for the order, if any
        uint256 refund = CalculatorHelper.calculateRefund(
            order.feeRateBps,
            feeAmount,
            order.side == Side.BUY
                ? CalculatorHelper.calculateTakingAmount(fillAmount, order.makerAmount, order.takerAmount)
                : fillAmount,
            order.makerAmount,
            order.takerAmount,
            order.side
        );

        uint256 id = order.side == Side.BUY ? order.tokenId : 0;
        address token = order.side == Side.BUY ? ctf : collateral;

        // If the refund is non-zero, transfer it to the order maker
        if (refund > 0) {
            _transfer(token, address(this), order.maker, id, refund);
            emit FeeRefunded(exchange.hashOrder(order), order.maker, id, refund, uint8(trader));
        }
    }
}
