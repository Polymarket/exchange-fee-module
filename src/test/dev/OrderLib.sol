// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Vm } from "forge-std/Vm.sol";

import { Order, Side, SignatureType } from "src/libraries/Structs.sol";

library OrderLib {
    Vm public constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function _createOrder(
        address maker,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side,
        uint256 feeRateBps
    ) internal pure returns (Order memory) {
        Order memory order = Order({
            salt: 1,
            signer: maker,
            maker: maker,
            taker: address(0),
            tokenId: tokenId,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: 0,
            nonce: 0,
            feeRateBps: feeRateBps,
            signatureType: SignatureType.EOA,
            side: side,
            signature: new bytes(0)
        });
        return order;
    }

    function _signMessage(uint256 pk, bytes32 message) internal pure returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, message);
        sig = abi.encodePacked(r, s, v);
    }

    function _signOrder(uint256 pk, bytes32 orderHash, Order memory order) internal pure returns (Order memory) {
        order.signature = _signMessage(pk, orderHash);
        return order;
    }
}
