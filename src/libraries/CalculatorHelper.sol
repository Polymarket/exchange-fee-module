// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order, Side } from "../libraries/Structs.sol";

library CalculatorHelper {
    uint256 internal constant ONE = 10 ** 18;

    uint256 internal constant BPS_DIVISOR = 10_000;

    /// @notice Calculates the fee refund for an Order
    /// @notice Used to refund Order makers if a user signs a fee into an Order that is > the expeceted fee
    /// @param orderFeeRateBps      - The fee rate signed into the order by the user
    /// @param operatorFeeRateBps   - The fee rate chosen by the operator
    /// @param outcomeTokens        - The number of outcome tokens
    /// @param makerAmount          - The maker amount of the order
    /// @param takerAmount          - The taker amount of the order
    /// @param side                 - The side of the order
    function calcRefund(
        uint256 orderFeeRateBps,
        uint256 operatorFeeRateBps,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256) {
        if (orderFeeRateBps <= operatorFeeRateBps) return 0;

        uint256 fee = calculateFee(orderFeeRateBps, outcomeTokens, makerAmount, takerAmount, side);

        // fee calced using order fee minus fee calced using the operator fee
        if (operatorFeeRateBps == 0) return fee;
        return fee - calculateFee(operatorFeeRateBps, outcomeTokens, makerAmount, takerAmount, side);
    }

    /// @notice Calculates the taking amount, i.e the amount of tokens to be received
    /// @param makingAmount - The making amount
    /// @param makerAmount  - The maker amount of the order
    /// @param takerAmount  - The taker amount of the order
    function calculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        internal
        pure
        returns (uint256)
    {
        if (makerAmount == 0) return 0;
        return makingAmount * takerAmount / makerAmount;
    }

    /// @notice Calculates the fee for an order
    /// @dev Fees are calculated based on amount of outcome tokens and the order's feeRate
    /// @param feeRateBps       - Fee rate, in basis points
    /// @param outcomeTokens    - The number of outcome tokens
    /// @param makerAmount      - The maker amount of the order
    /// @param takerAmount      - The taker amount of the order
    /// @param side             - The side of the order
    function calculateFee(
        uint256 feeRateBps,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256 fee) {
        if (feeRateBps > 0) {
            uint256 price = _calculatePrice(makerAmount, takerAmount, side);
            if (price > 0 && price <= ONE) {
                if (side == Side.BUY) {
                    // Fee charged on Token Proceeds:
                    // baseRate * min(price, 1-price) * (outcomeTokens/price)
                    fee = (feeRateBps * min(price, ONE - price) * outcomeTokens) / (price * BPS_DIVISOR);
                } else {
                    // Fee charged on Collateral proceeds:
                    // baseRate * min(price, 1-price) * outcomeTokens
                    fee = feeRateBps * min(price, ONE - price) * outcomeTokens / (BPS_DIVISOR * ONE);
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) internal pure returns (uint256) {
        if (side == Side.BUY) return takerAmount != 0 ? makerAmount * ONE / takerAmount : 0;
        return makerAmount != 0 ? takerAmount * ONE / makerAmount : 0;
    }
}
