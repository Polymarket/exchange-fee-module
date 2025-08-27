// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Auth } from "./mixins/Auth.sol";
import { IFeeModule } from "./interfaces/IFeeModule.sol";

struct WithdrawOpts {
    uint256 tokenId;
    address to;
    uint256 amount;
}

contract Collector is Auth {
    IFeeModule public immutable feeModule;

    constructor(address _feeModule) {
        feeModule = IFeeModule(_feeModule);
    }

    function withdrawFees(WithdrawOpts[] calldata opts) external onlyAdmin {
        for (uint256 i = 0; i < opts.length; ++i) {
            WithdrawOpts memory opt = opts[i];
            feeModule.withdrawFees(opt.to, opt.tokenId, opt.amount);
        }
    }
}
