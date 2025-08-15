# Polymarket CTF Exchange Fee Module

The `FeeModule` contract proxies the `Exchange`'s `matchOrders` function and refunds orders' fees if they are charged more than the operator's intent.


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
