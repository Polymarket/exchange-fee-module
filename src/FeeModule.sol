// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC1155TokenReceiver } from "solmate/tokens/ERC1155.sol";

import { Auth } from "./mixins/Auth.sol";
import { Order } from "./libraries/OrderStructs.sol";
import { IFeeModule } from "./interfaces/IFeeModule.sol";


/// @title Polymarket CTF Fee Module
/// @notice Proxies the CTFExchange contract and refunds maker orders
/// @author Jonathan Amenechi (jon@polymarket.com)
contract FeeModule is IFeeModule, Auth, ERC1155TokenReceiver {
    
    /// @notice Matches a taker order against a list of maker orders, refunding maker orders if necessary
    /// @param takerOrder       - The active order to be matched
    /// @param makerOrders      - The array of maker orders to be matched against the active order
    /// @param takerFillAmount  - The amount to fill on the taker order, always in terms of the maker amount
    /// @param makerFillAmounts - The array of amounts to fill on the maker orders, always in terms of the maker amount
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external onlyAdmin {
        
    }
}
