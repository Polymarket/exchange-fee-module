// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { CollectorTestHelper } from "./dev/CollectorTestHelper.sol";

import { WithdrawOpts } from "src/Collector.sol";

contract CollectorTest is CollectorTestHelper {
    function testSetup() public {
        assertEq(address(feeModule), address(collector.feeModule()));
    }

    function testWithdrawFees(uint64 _amount) public {
        vm.assume(_amount > 0);
        uint256 amount = uint256(_amount);
        WithdrawOpts[] memory opts = new WithdrawOpts[](3);
        opts[0] = _createWithdrawOpts(0, brian, amount);
        opts[1] = _createWithdrawOpts(yes, brian, amount);
        opts[2] = _createWithdrawOpts(no, brian, amount);

        // deal tokens to the fee module
        _mintTokens(address(feeModule), amount);

        vm.prank(admin);
        collector.withdrawFees(opts);

        // Assert balances
        assertEq(amount, balanceOf(address(usdc), brian));
        assertEq(amount, balanceOf1155(address(ctf), brian, yes));
        assertEq(amount, balanceOf1155(address(ctf), brian, no));
    }
}
