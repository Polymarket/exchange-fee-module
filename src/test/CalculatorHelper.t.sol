// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "lib/forge-std/src/Test.sol";

import { Side } from "src/libraries/Structs.sol";
import { CalculatorHelper } from "src/libraries/CalculatorHelper.sol";

contract CalculatorHelperTest is Test {
    function testCalculateRefund(
        uint8 _orderFeeRate,
        uint64 _operatorFeeAmount,
        uint64 outcomeTokens,
        uint64 makerAmount,
        uint64 takerAmount,
        uint8 _side
    ) public view {
        uint256 orderFeeRate = bound(uint256(_orderFeeRate), 1, 1000);
        uint256 operatorFeeAmount = bound(uint256(_operatorFeeAmount), 1, 1_000_000);
        vm.assume(makerAmount > 0 && outcomeTokens <= makerAmount);
        vm.assume(_side <= 1);
        Side side = Side(_side);

        CalculatorHelper.calculateRefund(orderFeeRate, operatorFeeAmount, outcomeTokens, makerAmount, takerAmount, side);
    }
}
