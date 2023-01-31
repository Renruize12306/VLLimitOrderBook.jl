# VLLimitOrderBook.jl
`VLLimitOrderBook.jl` is a package that simulates the dynamics of an [Order Book](https://www.investopedia.com/terms/o/order-book.asp). An order book is an electronic list of buy and sell orders for a specific security, which is used to help illustrate the dynamics for that security. This package was based on the previous work of [p-casgrain Philippe Casgrain](https://github.com/p-casgrain) and [dm13450 Dean](https://github.com/dm13450) in the package [LimitOrderBook.jl](https://github.com/p-casgrain/LimitOrderBook.jl).

## Overview
The original package has the following features:
* Submit and cancel limit orders and submit market orders.
* Inspect the order book information and statistics.
* Save the order book state to a CSV file.
 
Additionally, the package has fixed the following bugs in the original implementation:
* The order book does not track specific users, causing the relevant account to not update when an order is matched and removed from the order book.
* The order book has errors in cross-matching at oneSideBook, causing errors to occur when an order is matched.

Based on original package, the following features have been added or modified:
* The ability to load the order book state from a CSV file.
* Improved code testing coverage.
* Added order types for stop-loss and buy stop orders.
* Implemented a notification feature when orders are matched.
* Includes benchmarks for performance evaluation.
* Validates accuracy and correctness of the order book using actual data from [Polygon](https://polygon.io/).

## Usage

### Install
```julia 
import Pkg; Pkg.add(url="https://github.com/Renruize12306/VLLimitOrderBook.jl.git")
```
### Example
```julia
using VLLimitOrderBook
using Dates
using Base.Iterators: zip, cycle, take

# # Define the types for order size, price, transaction ID, account ID, order creation time, IP address, and port
# Define the types for order size, price, order ID, and account ID
MyLOBType = OrderBook{Float64, Float64, Int64, Int64}

# Initialize an empty order book and unmatched order book process
ob = MyLOBType()

# Create a deterministic limit order generator
orderid_iter = Base.Iterators.countfrom(1)
sign_iter = cycle([1, -1, 1, -1])
side_iter = (s > 0 ? SELL_ORDER : BUY_ORDER for s in sign_iter)
spread_iter = cycle([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]*1e-2)
price_iter = (Float32(99.0 + sgn*δ) for (δ, sgn) in zip(spread_iter, sign_iter))
size_iter = cycle([10, 11, 20, 21, 30, 31, 40, 41, 50, 51])

# Zip them all together
lmt_order_info_iter = zip(orderid_iter, price_iter, size_iter, side_iter)

order_info_lst = take(lmt_order_info_iter, 6)

# Submit limit orders
for (orderid, price, size, side) in order_info_lst
    submit_limit_order!(ob,orderid,side,price,size,10101)
    print(orderid, ' ',side,' ',price,'\n')
end
```
**To inspect the order book**
```julia
ob
```
**An example to matching a limit order**
```julia
submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 5, 101111, FILLORKILL_FILLTYPE)
```