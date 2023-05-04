// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { TransferHelper } from "../libraries/TransferHelper.sol";

contract Transfers {
    /// @notice Transfers tokens. no-op if amount is zero
    /// @param token    - The Token to be transferred
    /// @param from     - The originating address
    /// @param to       - The destination address
    /// @param id       - The TokenId to be transferred, 0 if ERC20
    /// @param amount   - The amount of tokens to be transferred
    function _transfer(address token, address from, address to, uint256 id, uint256 amount) internal {
        if (amount > 0) {
            if (id == 0) {
                return from == address(this)
                    ? TransferHelper._transferERC20(token, to, amount)
                    : TransferHelper._transferFromERC20(token, from, to, amount);
            }
            return TransferHelper._transferFromERC1155(token, from, to, id, amount);
        }
    }
}
