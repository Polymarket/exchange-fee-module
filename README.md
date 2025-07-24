# Polymarket CTF Exchange Fee Module

The `FeeModule` contract proxies the `Exchange`'s `matchOrders` function and refunds orders' fees if they are charged more than the operator's intent.


## Deployments
| Network          | Address                                                                           |
| ---------------- | --------------------------------------------------------------------------------- |
| Polygon          |[0x56C79347e95530c01A2FC76E732f9566dA16E113](https://polygonscan.com/address/0x56C79347e95530c01A2FC76E732f9566dA16E113)|
| Mumbai           |[0x56C79347e95530c01A2FC76E732f9566dA16E113](https://mumbai.polygonscan.com/address/0x56C79347e95530c01A2FC76E732f9566dA16E113)|

## Functions

The contract exposes a single main entry point:

```[solidity]
function matchOrders(
    Order memory takerOrder,
    Order[] memory makerOrders,
    uint256 takerFillAmount,
    uint256[] memory makerFillAmounts,
    uint256 takerFeeAmount,
    uint256[] memory makerFeeAmounts
) external;
```
