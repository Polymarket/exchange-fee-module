# Polymarket CTF Exchange Fee Module

The `FeeModule` contract proxies the `Exchange`'s `matchOrders` function and refunds maker orders if they are overcharged.


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
    uint256 makerFeeRate
) external;
```

## Description

GTC taker orders that are marketable, but are not completely filled, will rest on the orderbook, becoming Maker orders. Because of this, they should be charged the maker fee rate.

But, the feeRateBps field is signed into the Order by the user, without knowing whether or not the Order will remain a taker order or a maker order. Since maker orders are usually charged (much) lower fees than taker orders, the order could be overcharged.

The FeeModule will refund maker orders which are overcharged.

