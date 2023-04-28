// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import "../src/FeeModule.sol";

contract FeeModuleTest is Test {

    function testEquals() public {
        uint256 x = 1;
        assertEq(1, x);
    }
}