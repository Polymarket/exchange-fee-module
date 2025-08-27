// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { console2 as console } from "lib/forge-std/src/Test.sol";

import { ERC1155 } from "lib/solmate/src/tokens/ERC1155.sol";

import { IFeeModule } from "../../interfaces/IFeeModule.sol";
import { IConditionalTokens } from "../../interfaces/IConditionalTokens.sol";

import { FeeModuleTestHelper } from "./FeeModuleTestHelper.sol";

import { WithdrawOpts, Collector } from "src/Collector.sol";

contract CollectorTestHelper is FeeModuleTestHelper {
    Collector public collector;

    function setUp() public override {
        FeeModuleTestHelper.setUp();
        collector = new Collector(address(feeModule));

        // Authorizations
        vm.prank(admin);
        feeModule.addAdmin(address(collector));

        collector.addAdmin(admin);
    }

    function _mintTokens(address to, uint256 amount) internal {
        // deal USDC
        deal(address(usdc), to, amount);

        // deal CTF Tokens by splitting
        _mintOutcomeTokens(to, amount);
    }

    function _mintOutcomeTokens(address to, uint256 amount) internal {
        vm.startPrank(admin);
        deal(address(usdc), admin, amount);

        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        approve(address(usdc), address(ctf), amount);

        IConditionalTokens(ctf).splitPosition(address(usdc), bytes32(0), conditionId, partition, amount);

        ERC1155(ctf).safeTransferFrom(admin, to, yes, amount, hex"");
        ERC1155(ctf).safeTransferFrom(admin, to, no, amount, hex"");
        vm.stopPrank();
    }

    function _createWithdrawOpts(uint256 tokenId, address to, uint256 amount)
        internal
        pure
        returns (WithdrawOpts memory)
    {
        return WithdrawOpts({ tokenId: tokenId, to: to, amount: amount });
    }
}
