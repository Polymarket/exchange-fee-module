// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "src/FeeModule.sol";
import { Side, Order } from "src/libraries/Structs.sol";

import { FeeModuleTestHelper } from "./dev/FeeModuleTestHelper.sol";

contract FeeModuleTest is FeeModuleTestHelper {
    function testSetup() public {
        assertEq(feeModule.collateral(), usdc);
        assertEq(feeModule.ctf(), ctf);
        assertTrue(feeModule.isAdmin(admin));
        assertFalse(feeModule.isAdmin(brian));
    }

    function testMatchOrdersZeroMakerFee() public {
        // Initialize a match with a buy vs a set of sell maker orders

        // Taker order 40c buy with a 10% fee
        uint256 takerFeeRateBps = 1000;
        Order memory buy = createAndSignOrder(bobPK, yes, 40_000_000, 100_000_000, Side.BUY, takerFeeRateBps);

        // Initialize maker orders with a fee rate bps
        // Meaning Maker orders which are erroneously charged fees and therefore should be refunded
        uint256 makerFeeRateBps = 100; // 1% Maker fee

        // SellA: Selling 60 YES tokens for 24 USDC, 40c YES sell, fully filled
        Order memory sellA = createAndSignOrder(carlaPK, yes, 60_000_000, 24_000_000, Side.SELL, makerFeeRateBps);

        // SellB: Selling 100 YES for 40 USDC, 40c YES sell, partialy filled
        Order memory sellB = createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL, makerFeeRateBps);

        Order[] memory sells = new Order[](2);
        sells[0] = sellA;
        sells[1] = sellB;

        uint256[] memory fillAmounts = new uint256[](2);
        uint256 sellAMaking = 60_000_000;
        uint256 sellBMaking = 40_000_000;
        fillAmounts[0] = sellAMaking;
        fillAmounts[1] = sellBMaking;

        uint256 takerFee = getExpectedFee(buy, 40_000_000);
        uint256 makerFeeA = getExpectedFee(sellA, sellAMaking);
        uint256 makerFeeB = getExpectedFee(sellB, sellBMaking);

        // Orders get matched correctly
        vm.expectEmit();
        emit OrderFilled(hashOrder(sellA), carla, bob, yes, 0, 60_000_000, 24_000_000, makerFeeA);

        vm.expectEmit();
        emit OrderFilled(hashOrder(sellB), carla, bob, yes, 0, 40_000_000, 16_000_000, makerFeeB);

        vm.expectEmit();
        emit OrderFilled(hashOrder(buy), bob, exchange, 0, yes, 40_000_000, 100_000_000, takerFee);

        vm.expectEmit();
        emit OrdersMatched(hashOrder(buy), bob, 0, yes, 40_000_000, 100_000_000);

        // Maker fees are refunded
        vm.expectEmit();
        emit FeeRefunded(usdc, carla, 0, makerFeeA);

        vm.expectEmit();
        emit FeeRefunded(usdc, carla, 0, makerFeeB);

        vm.prank(admin);
        feeModule.matchOrders(buy, sells, 40_000_000, fillAmounts, 0);

        // Assert balance changes
        // Taker fee collected on the taker order on the fee module, denominated in YES token
        assertEq(takerFee, balanceOf1155(ctf, address(feeModule), yes));
    }

    function testMatchOrdersPartialFill() public {
        // Call match orders using a partially filled order
        testMatchOrdersZeroMakerFee();
        uint256 makerFee = 100;
        uint256 takerFee = 1000;
        uint256 operatorFee = 0;

        // Partially filled YES sell
        Order memory yesSell = createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL, makerFee);
        Order[] memory makerOrders= new Order[](1);
        makerOrders[0] = yesSell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 60_000_000;

        // New NO sell taker order
        Order memory noSell = createAndSignOrder(bobPK, no, 60_000_000, 24_000_000, Side.SELL, takerFee);

        vm.expectEmit();
        emit FeeRefunded(usdc, carla, 0, 240000);

        vm.prank(admin);
        feeModule.matchOrders(noSell, makerOrders, 60_000_000, fillAmounts, operatorFee);
    }

    function testMatchOrdersNonZeroMakerFee() public {
        uint256 operatorFeeRate = 30; // 0.3% Maker Fee Rate

        // 50c Buy order
        uint256 takerFeeRateBps = 500; // 5% Taker fee signed into Order
        Order memory buy = createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY, takerFeeRateBps);

        // 50c Sell Maker Order
        uint256 makerFeeRateBps = 100; // 1% Maker fee signed into Order
        Order memory sell = createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL, makerFeeRateBps);

        Order[] memory sells = new Order[](1);
        sells[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        uint256 makerFill = 100_000_000;
        uint256 takerFill = 50_000_000;
        fillAmounts[0] = makerFill;

        // Operator defined maker fee rate < Order fee rate, so the difference will be refunded
        // Operator maker fee rate = 0.3%, Order fee rate = 1%
        uint256 refund = CalculatorHelper.calcRefund(
            sell.feeRateBps, operatorFeeRate, makerFill, sell.makerAmount, sell.takerAmount, sell.side
        );

        vm.expectEmit();
        emit FeeRefunded(usdc, carla, 0, refund);

        vm.prank(admin);
        feeModule.matchOrders(buy, sells, takerFill, fillAmounts, operatorFeeRate);
    }

    function testMatchOrdersNoRefundSameFee() public {
        uint256 takerFeeRateBps = 500;
        Order memory buy = createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY, takerFeeRateBps);

        uint256 makerFeeRateBps = 30;
        Order memory sell = createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL, makerFeeRateBps);

        Order[] memory sells = new Order[](1);
        sells[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        uint256 makerFill = 100_000_000;
        uint256 takerFill = 50_000_000;
        fillAmounts[0] = makerFill;

        uint256 operatorFeeRate = 30;

        // Order fee matches operator fee, no refund
        assertEq(
            CalculatorHelper.calcRefund(
                sell.feeRateBps, operatorFeeRate, makerFill, sell.makerAmount, sell.takerAmount, sell.side
            ),
            0
        );

        // Orders matched without emitting the refund event
        vm.prank(admin);
        feeModule.matchOrders(buy, sells, takerFill, fillAmounts, operatorFeeRate);
    }

    function testMatchOrdersNoRefundLowerFee() public {
        uint256 takerFeeRateBps = 500;
        Order memory buy = createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY, takerFeeRateBps);

        uint256 makerFeeRateBps = 30;
        Order memory sell = createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL, makerFeeRateBps);

        Order[] memory sells = new Order[](1);
        sells[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        uint256 makerFill = 100_000_000;
        uint256 takerFill = 50_000_000;
        fillAmounts[0] = makerFill;

        uint256 operatorFeeRate = 100;

        // Order fee < operator fee, no refund
        assertEq(
            CalculatorHelper.calcRefund(
                sell.feeRateBps, operatorFeeRate, makerFill, sell.makerAmount, sell.takerAmount, sell.side
            ),
            0
        );

        // Orders matched without emitting the refund event
        vm.prank(admin);
        feeModule.matchOrders(buy, sells, takerFill, fillAmounts, operatorFeeRate);
    }

    function testMatchOrdersFuzz(
        uint64 fillAmount,
        uint16 takerFeeRateBps,
        uint16 makerFeeRateBps,
        uint16 operatorFeeRateBps
    ) public {
        uint256 makerAmount = 50_000_000;
        uint256 takerAmount = 100_000_000;
        
        vm.assume(
            fillAmount <= makerAmount && 
            takerFeeRateBps < getMaxFeeRate() &&
            makerFeeRateBps < getMaxFeeRate() &&
            operatorFeeRateBps < getMaxFeeRate()
        );

        Order memory buy = createAndSignOrder(bobPK, yes, makerAmount, takerAmount, Side.BUY, uint256(takerFeeRateBps));
        Order memory sell = createAndSignOrder(carlaPK, yes, takerAmount, makerAmount, Side.SELL, uint256(makerFeeRateBps));

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        uint256 makerFillAmount = fillAmount * takerAmount / makerAmount;
        fillAmounts[0] = makerFillAmount;

        uint256 refund = getRefund(sell, makerFillAmount, operatorFeeRateBps);
        if (refund > 0) {
            vm.expectEmit();
            emit FeeRefunded(usdc, carla, 0, refund);
        }
        vm.prank(admin);
        feeModule.matchOrders(buy, makerOrders, fillAmount, fillAmounts, operatorFeeRateBps);
    }

    function testWithdrawERC1155() public {
        _transfer(ctf, bob, address(feeModule), yes, 100_000_000);

        uint256 amt = balanceOf1155(ctf, address(feeModule), yes);
        vm.expectEmit();
        emit FeeWithdrawn(ctf, admin, yes, amt);

        // Withdraw tokens
        vm.prank(admin);
        feeModule.withdrawFees(admin, yes, amt);

        assertEq(balanceOf1155(ctf, admin, yes), amt);
        assertEq(balanceOf1155(ctf, address(feeModule), yes), 0);
    }

    function testWithdrawERC20() public {
        _transfer(usdc, bob, address(feeModule), 0, 100_000_000);

        uint256 amt = balanceOf(usdc, address(feeModule));
        vm.expectEmit();
        emit FeeWithdrawn(usdc, admin, 0, amt);

        // Withdraw tokens
        vm.prank(admin);
        feeModule.withdrawFees(admin, 0, amt);

        assertEq(balanceOf(usdc, admin), amt);
        assertEq(balanceOf(usdc, address(feeModule)), 0);
    }
}
