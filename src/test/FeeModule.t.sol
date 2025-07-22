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
        // User signed fees
        uint256 takerFeeRateBps = 1000; // 10% Taker fee
        uint256 makerFeeRateBps = 100; // 1% Maker fee

        // Operator fees
        uint256 operatorTakerFeeRateBps = 500; // 5% Operator taker fee rate
        uint256 operatorMakerFeeRateBps = 0; // 0% Operator maker fee rate

        // Maker orders are erroneously charged higher fees than the operator inteded and should be refunded
        // The taker order is also charged higher fees than the operator intended and should be refunded

        // Taker order 40c buy with a 10% signed user fee
        Order memory buy = createAndSignOrder(bobPK, yes, 40_000_000, 100_000_000, Side.BUY, takerFeeRateBps);

        // Initialize maker orders with signed user fees
        // SellA: Selling 60 YES tokens for 24 USDC, 40c YES sell, fully filled
        Order memory sellA = createAndSignOrder(carlaPK, yes, 60_000_000, 24_000_000, Side.SELL, makerFeeRateBps);
        // SellB: Selling 100 YES for 40 USDC, 40c YES sell, partialy filled
        Order memory sellB = createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL, makerFeeRateBps);

        Order[] memory sells = new Order[](2);
        sells[0] = sellA;
        sells[1] = sellB;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 60_000_000;
        fillAmounts[1] = 40_000_000;

        uint256 takerFee = getExpectedFee(buy, 40_000_000);

        // Orders get matched correctly
        vm.expectEmit();
        emit OrderFilled(hashOrder(sellA), carla, bob, yes, 0, 60_000_000, 24_000_000, getExpectedFee(sellA, 60_000_000));

        vm.expectEmit();
        emit OrderFilled(hashOrder(sellB), carla, bob, yes, 0, 40_000_000, 16_000_000, getExpectedFee(sellB, 40_000_000));

        vm.expectEmit();
        emit OrderFilled(hashOrder(buy), bob, exchange, 0, yes, 40_000_000, 100_000_000, takerFee);

        vm.expectEmit();
        emit OrdersMatched(hashOrder(buy), bob, 0, yes, 40_000_000, 100_000_000);

        // Taker fees are refunded
        vm.expectEmit();
        emit FeeRefunded(uint8(Trader.TAKER), ctf, bob, yes, getRefund(buy, 40_000_000, operatorTakerFeeRateBps));
        
        // Maker fees are refunded
        vm.expectEmit();
        emit FeeRefunded(uint8(Trader.MAKER), usdc, carla, 0, getRefund(sellA, 60_000_000, operatorMakerFeeRateBps));

        vm.expectEmit();
        emit FeeRefunded(uint8(Trader.MAKER), usdc, carla, 0, getRefund(sellB, 40_000_000, operatorMakerFeeRateBps));

        vm.prank(admin);
        feeModule.matchOrders(
            buy, sells, 40_000_000, fillAmounts, operatorTakerFeeRateBps, operatorMakerFeeRateBps
        );

        // Assert balance changes
        // Taker fee collected on the taker order on the fee module, denominated in YES token
        assertEq(
            takerFee - getRefund(buy, 40_000_000, operatorTakerFeeRateBps),
            balanceOf1155(ctf, address(feeModule), yes)
        );
    }

    function testMatchOrdersMatchTypeMerge() public {
        // User signed fees
        uint256 makerFee = 100;
        uint256 takerFee = 1000;

        // Operator fees
        uint256 operatorMakerFeeRateBps = 0;
        uint256 operatorTakerFeeRateBps = 500;

        // YES sell maker order
        Order memory yesSell = createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL, makerFee);
        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = yesSell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 60_000_000;

        // NO sell taker order
        Order memory noSell = createAndSignOrder(bobPK, no, 60_000_000, 24_000_000, Side.SELL, takerFee);

        // fees collected in USDC
        vm.expectEmit();
        emit FeeRefunded(uint8(Trader.TAKER), usdc, bob, 0, 1_200_000);
        
        vm.expectEmit();
        emit FeeRefunded(uint8(Trader.MAKER), usdc, carla, 0, 240_000);

        vm.prank(admin);
        feeModule.matchOrders(noSell, makerOrders, 60_000_000, fillAmounts, operatorTakerFeeRateBps, operatorMakerFeeRateBps);
    }

    function testMatchOrdersMatchTypeMint() public {
        // User signed fees
        uint256 makerFee = 100;
        uint256 takerFee = 1000;
        
        // Operator fees
        uint256 operatorMakerFeeRateBps = 0;
        uint256 operatorTakerFeeRateBps = 500;

        // YES BUY maker order
        Order memory yesBuy = createAndSignOrder(carlaPK, yes, 40_000_000, 100_000_000, Side.BUY, makerFee);
        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = yesBuy;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 40_000_000;

        // NO BUY taker order
        Order memory noBuy = createAndSignOrder(bobPK, no, 60_000_000, 100_000_000, Side.BUY, takerFee);

        vm.expectEmit();
        // fees collected in tokens
        emit FeeRefunded(uint8(Trader.TAKER), ctf, bob, no, 3_333_333);
        
        vm.expectEmit();
        emit FeeRefunded(uint8(Trader.MAKER), ctf, carla, yes, 1_000_000);

        vm.prank(admin);
        feeModule.matchOrders(noBuy, makerOrders, 60_000_000, fillAmounts, operatorTakerFeeRateBps, operatorMakerFeeRateBps);
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
