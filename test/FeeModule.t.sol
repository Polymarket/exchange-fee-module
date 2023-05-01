// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../src/FeeModule.sol";

import { Side, Order } from "../src/libraries/Structs.sol";

import { FeeModuleTestHelper } from "./dev/FeeModuleTestHelper.sol";

import { console } from "forge-std/console.sol";

contract FeeModuleTest is FeeModuleTestHelper {
    function testSetup() public {
        assertEq(feeModule.collateral(), usdc);
        assertEq(feeModule.ctf(), ctf);
        assertTrue(feeModule.isAdmin(admin));
        assertFalse(feeModule.isAdmin(brian));
    }

    function testMatchOrders() public {
        // Initialize a match with a buy vs a set of sell maker orders

        // Taker order 40c buy with a 10% fee
        uint256 takerFeeRateBps = 1000;
        Order memory buy = createAndSignOrder(bobPK, yes, 40_000_000, 100_000_000, Side.BUY, takerFeeRateBps);

        // Initialize maker orders with a fee rate bps
        // Meaning Maker orders which are erroneously charged fees and therefore should be refunded
        uint256 makerFeeRateBps = 100; // 1% Maker fee
        
        // SellA: Selling 65 YES tokens for 26 USDC, 40c YES sell, fully filled
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
        // Taker fee collected on the taker order, denominated in YES token
        assertEq(takerFee, balanceOf1155(ctf, address(feeModule), yes));
    }


}
