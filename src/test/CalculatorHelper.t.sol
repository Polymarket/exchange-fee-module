// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "lib/forge-std/src/Test.sol";

import { Side } from "src/libraries/Structs.sol";
import { CalculatorHelper } from "src/libraries/CalculatorHelper.sol";

contract CalculatorHelperTest is Test {
    function testcalculateRefund(
        uint8 orderFeeRate,
        uint8 operatorFeeRate,
        uint64 outcomeTokens,
        uint64 makerAmount,
        uint64 takerAmount,
        uint8 sideInt
    ) public pure {
        vm.assume(orderFeeRate >= 0);
        vm.assume(operatorFeeRate >= 0);
        vm.assume(makerAmount > 0 && outcomeTokens <= makerAmount);
        vm.assume(sideInt <= 1);
        Side side = Side(sideInt);

        CalculatorHelper.calculateRefund(orderFeeRate, operatorFeeRate, outcomeTokens, makerAmount, takerAmount, side);
    }
}
