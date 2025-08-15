// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Order, Side } from "../libraries/Structs.sol";

library CalculatorHelper {
    uint256 internal constant ONE = 10 ** 18;

    uint256 internal constant BPS_DIVISOR = 10_000;

    /// @notice Calculates the fee refund for an Order
    /// @notice Used to refund Order makers if a user signs a fee into an Order that is greater than the expected operator fee
    /// @param orderFeeRateBps      - The fee rate signed into the order by the user
    /// @param operatorFeeAmount    - The fee amount calculated by the operator.
    /// @dev This fee cannot exceed the fee implied by the fee rate bps in the order.
    /// @param outcomeTokens        - The number of outcome tokens
    /// @param makerAmount          - The maker amount of the order
    /// @param takerAmount          - The taker amount of the order
    /// @param side                 - The side of the order
    function calculateRefund(
        uint256 orderFeeRateBps,
        uint256 operatorFeeAmount,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256) {
        // Calculates the fee charged by the exchange
        uint256 exchangeFeeAmount = calculateExchangeFee(orderFeeRateBps, outcomeTokens, makerAmount, takerAmount, side);

        // Exchange fee must be greater than the operator fee
        if (exchangeFeeAmount <= operatorFeeAmount) return 0;

        return exchangeFeeAmount - operatorFeeAmount;
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

    /// @notice Calculates the fee charged by the CTF Exchange on an order
    /// @dev This function executes the onchain fee calculation done on the CTF Exchange
    /// @dev Fees are calculated based on amount of outcome tokens and the order's feeRate
    /// @param feeRateBps       - Fee rate, in basis points
    /// @param outcomeTokens    - The number of outcome tokens
    /// @param makerAmount      - The maker amount of the order
    /// @param takerAmount      - The taker amount of the order
    /// @param side             - The side of the order
    function calculateExchangeFee(
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
