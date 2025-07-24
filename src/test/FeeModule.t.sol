// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "src/FeeModule.sol";
import { Side, Order, Trader } from "src/libraries/Structs.sol";

import { FeeModuleTestHelper } from "./dev/FeeModuleTestHelper.sol";

contract FeeModuleTest is FeeModuleTestHelper {
    function testSetup() public {
        assertEq(feeModule.collateral(), usdc);
        assertEq(feeModule.ctf(), ctf);
        assertEq(address(feeModule.exchange()), exchange);
        assertTrue(feeModule.isAdmin(admin));
        assertFalse(feeModule.isAdmin(brian));
    }

    function testMatchOrders() public {
        // Initialize a match with a buy vs a set of sell maker orders

        // Taker order 40c buy, 40 USDC for 100 YES with a signed 10% user fee
        Order memory takerOrder = createAndSignOrder(bobPK, yes, 40_000_000, 100_000_000, Side.BUY, 1000);

        // Initialize maker orders with signed user fees
        // SellA: Selling 60 YES tokens for 24 USDC, 40c YES sell, fully filled, 1% Maker Fee
        Order memory makerOrderA = createAndSignOrder(carlaPK, yes, 60_000_000, 24_000_000, Side.SELL, 100);
        // SellB: Selling 100 YES for 40 USDC, 40c YES sell, partialy filled, 1% Maker Fee
        Order memory makerOrderB = createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL, 100);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrderA;
        makerOrders[1] = makerOrderB;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 60_000_000;
        fillAmounts[1] = 40_000_000;

        // Operator fee amounts
        // Operator levies a 5% flat fee on the taker order proceeds
        uint256 operatorTakerFeeAmount = 5_000_000;

        // Operator levies a 0.5% flat fee on the maker orders' proceeds
        uint256 operatorMakerFeeAmountA = 120_000;
        uint256 operatorMakerFeeAmountB = 80_000;

        uint256[] memory operatorMakerFeeAmounts = new uint256[](2);
        operatorMakerFeeAmounts[0] = operatorMakerFeeAmountA;
        operatorMakerFeeAmounts[1] = operatorMakerFeeAmountB;

        // The difference between the Exchange fees and the Operator fees are refunded
        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(takerOrder),
            bob,
            yes,
            getRefund(takerOrder, 40_000_000, operatorTakerFeeAmount),
            uint8(Trader.TAKER)
        );

        // Maker fees are refunded
        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(makerOrderA),
            carla,
            0,
            getRefund(makerOrderA, 60_000_000, operatorMakerFeeAmountA),
            uint8(Trader.MAKER)
        );

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(makerOrderB),
            carla,
            0,
            getRefund(makerOrderB, 40_000_000, operatorMakerFeeAmountB),
            uint8(Trader.MAKER)
        );

        vm.prank(admin);
        feeModule.matchOrders(
            takerOrder, makerOrders, 40_000_000, fillAmounts, operatorTakerFeeAmount, operatorMakerFeeAmounts
        );

        // Assert post execution balance changes
        // Taker fee collected on the taker order on the fee module, denominated in YES token
        assertEq(operatorTakerFeeAmount, balanceOf1155(ctf, address(feeModule), yes));

        // Total maker fees collected on the maker orders, denominated in USDC
        assertEq((operatorMakerFeeAmountA + operatorMakerFeeAmountB), balanceOf(usdc, address(feeModule)));
    }

    function testMatchOrdersMatchTypeMerge() public {
        // Initialize a match with a taker sell vs a set of sell maker orders

        // Taker order 40c sell, 100 YES for 40 USDC with a signed 10% user fee
        Order memory takerOrder = createAndSignOrder(bobPK, yes, 100_000_000, 40_000_000, Side.SELL, 1000);

        // Initialize maker orders with signed user fees
        // SellA: Selling 60 NO tokens for 24 USDC, fully filled, 1% Maker Fee
        Order memory makerOrderA = createAndSignOrder(carlaPK, no, 60_000_000, 24_000_000, Side.SELL, 100);
        // SellB: Selling 40 NO for 16 USDC, partialy filled, 1.5% Maker Fee
        Order memory makerOrderB = createAndSignOrder(carlaPK, no, 40_000_000, 16_000_000, Side.SELL, 150);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrderA;
        makerOrders[1] = makerOrderB;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 60_000_000;
        fillAmounts[1] = 40_000_000;

        // Operator fee amounts
        // Operator levies a 5% flat fee on the taker order proceeds
        uint256 operatorTakerFeeAmount = 2_000_000; // 2 USDC

        // Operator levies a 0.5% flat fee on the maker orders' proceeds
        uint256 operatorMakerFeeAmountA = 120_000; // 0.12 USDC
        uint256 operatorMakerFeeAmountB = 80_000; // 0.8 USDC

        uint256[] memory operatorMakerFeeAmounts = new uint256[](2);
        operatorMakerFeeAmounts[0] = operatorMakerFeeAmountA;
        operatorMakerFeeAmounts[1] = operatorMakerFeeAmountB;

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(takerOrder),
            bob,
            0,
            getRefund(takerOrder, 100_000_000, operatorTakerFeeAmount),
            uint8(Trader.TAKER)
        );

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(makerOrderA),
            carla,
            0,
            getRefund(makerOrderA, 60_000_000, operatorMakerFeeAmountA),
            uint8(Trader.MAKER)
        );

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(makerOrderB),
            carla,
            0,
            getRefund(makerOrderB, 40_000_000, operatorMakerFeeAmountB),
            uint8(Trader.MAKER)
        );

        vm.prank(admin);
        feeModule.matchOrders(
            takerOrder, makerOrders, 100_000_000, fillAmounts, operatorTakerFeeAmount, operatorMakerFeeAmounts
        );

        // Assert post execution balance changes
        // Total Fees collected in USDC
        assertEq(
            operatorTakerFeeAmount + operatorMakerFeeAmountA + operatorMakerFeeAmountB,
            balanceOf(usdc, address(feeModule))
        );
    }

    function testMatchOrdersMatchTypeMint() public {
        // Initialize a match with a taker buy vs a set of buy maker orders

        // Taker order 40c buy, 60 USDC for 100 YES with a signed 10% user fee
        Order memory takerOrder = createAndSignOrder(bobPK, yes, 60_000_000, 100_000_000, Side.BUY, 1000);

        // Initialize maker orders with signed user fees
        // BuyA: Buying 50 NO tokens for 25 USDC, 1% Maker Fee
        Order memory makerOrderA = createAndSignOrder(carlaPK, no, 25_000_000, 50_000_000, Side.BUY, 100);
        // BuyB: Buying 50 NO for 20 USDC, 1% Maker Fee
        Order memory makerOrderB = createAndSignOrder(carlaPK, no, 20_000_000, 50_000_000, Side.BUY, 100);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrderA;
        makerOrders[1] = makerOrderB;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 25_000_000;
        fillAmounts[1] = 20_000_000;

        // Operator fee amounts
        // Operator levies a 5% flat fee on the taker order proceeds
        uint256 operatorTakerFeeAmount = 5_000_000; // 5 YES

        // Operator levies a 0.5% flat fee on the maker orders' proceeds
        uint256 operatorMakerFeeAmountA = 125_000; // 0.125 YES
        uint256 operatorMakerFeeAmountB = 100_000; // 0.1 YES

        uint256[] memory operatorMakerFeeAmounts = new uint256[](2);
        operatorMakerFeeAmounts[0] = operatorMakerFeeAmountA;
        operatorMakerFeeAmounts[1] = operatorMakerFeeAmountB;

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(takerOrder),
            bob,
            yes,
            getRefund(takerOrder, 60_000_000, operatorTakerFeeAmount),
            uint8(Trader.TAKER)
        );

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(makerOrderA),
            carla,
            no,
            getRefund(makerOrderA, 25_000_000, operatorMakerFeeAmountA),
            uint8(Trader.MAKER)
        );

        vm.expectEmit();
        emit FeeRefunded(
            hashOrder(makerOrderB),
            carla,
            no,
            getRefund(makerOrderB, 20_000_000, operatorMakerFeeAmountB),
            uint8(Trader.MAKER)
        );

        vm.prank(admin);
        feeModule.matchOrders(
            takerOrder, makerOrders, 60_000_000, fillAmounts, operatorTakerFeeAmount, operatorMakerFeeAmounts
        );

        // Assert post execution balance changes
        // Total Fees collected in CTF tokens
        assertEq(operatorTakerFeeAmount, balanceOf1155(ctf, address(feeModule), yes));
        assertEq(operatorMakerFeeAmountA + operatorMakerFeeAmountB, balanceOf1155(ctf, address(feeModule), no));
    }

    function testMatchOrdersFuzz(uint64 takerFillAmount, uint16 takerFeeRateBps, uint16 makerFeeRateBps) public {
        vm.assume(
            takerFillAmount <= 50_000_000 && takerFeeRateBps > 100 && takerFeeRateBps < getMaxFeeRate()
                && makerFeeRateBps > 10 && makerFeeRateBps < getMaxFeeRate()
        );

        Order memory takerOrder =
            createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY, uint256(takerFeeRateBps));
        Order memory makerOrder =
            createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL, uint256(makerFeeRateBps));

        uint256 makerFillAmount = takerFillAmount * 100_000_000 / 50_000_000;

        // Apply a 0.5 haircut to the exchange fee
        uint256 operatorTakerFeeAmount = getOperatorFee(takerOrder, takerFillAmount, 500_000);
        uint256[] memory operatorMakerFeeAmounts = new uint256[](1);
        operatorMakerFeeAmounts[0] = getOperatorFee(makerOrder, makerFillAmount, 500_000);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory makerFillAmounts = new uint256[](1);

        makerFillAmounts[0] = makerFillAmount;

        uint256 takerRefund = getRefund(takerOrder, takerFillAmount, operatorTakerFeeAmount);
        if (takerRefund > 0) {
            vm.expectEmit();
            emit FeeRefunded(hashOrder(takerOrder), bob, yes, takerRefund, uint8(Trader.TAKER));
        }

        uint256 makerRefund = getRefund(makerOrder, makerFillAmount, operatorMakerFeeAmounts[0]);
        if (makerRefund > 0) {
            vm.expectEmit();
            emit FeeRefunded(hashOrder(makerOrder), carla, 0, makerRefund, uint8(Trader.MAKER));
        }

        vm.prank(admin);
        feeModule.matchOrders(
            takerOrder, makerOrders, takerFillAmount, makerFillAmounts, operatorTakerFeeAmount, operatorMakerFeeAmounts
        );
    }

    function testWithdrawERC1155() public {
        _transfer(ctf, bob, address(feeModule), yes, 100_000_000);

        uint256 amount = balanceOf1155(ctf, address(feeModule), yes);
        vm.expectEmit();
        emit FeeWithdrawn(ctf, admin, yes, amount);

        // Withdraw tokens
        vm.prank(admin);
        feeModule.withdrawFees(admin, yes, amount);

        assertEq(balanceOf1155(ctf, admin, yes), amount);
        assertEq(balanceOf1155(ctf, address(feeModule), yes), 0);
    }

    function testWithdrawERC20() public {
        _transfer(usdc, bob, address(feeModule), 0, 100_000_000);

        uint256 amount = balanceOf(usdc, address(feeModule));
        vm.expectEmit();
        emit FeeWithdrawn(usdc, admin, 0, amount);

        // Withdraw tokens
        vm.prank(admin);
        feeModule.withdrawFees(admin, 0, amount);

        assertEq(balanceOf(usdc, admin), amount);
        assertEq(balanceOf(usdc, address(feeModule)), 0);
    }
}
