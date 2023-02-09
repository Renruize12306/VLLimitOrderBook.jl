module VLLimitOrderBook
using AVLTrees: AVLTree
using Base: @kwdef
using Printf
include("broadcast.jl")
include("orderqueue.jl")
include("sidebook.jl")
include("book.jl")
include("ordermatching.jl")
export BUY_ORDER, SELL_ORDER, VANILLA_FILLTYPE, IMMEDIATEORCANCEL_FILLTYPE, FILLORKILL_FILLTYPE, ALLORNONE_FILLTYPE
export OrderBook, Order, OrderTraits, AcctMap, OrderSide
export Monetary, AssetMismatch
export submit_order!,
    submit_limit_order!,
    cancel_order!,
    submit_market_order!,
    submit_market_order_byfunds!,
    clear_book!,
    book_depth_info,
    volume_bid_ask,
    best_bid_ask,
    n_orders_bid_ask,
    bid_orders,
    ask_orders,
    get_acct,
    write_to_csv,
    read_from_csv,
    order_types
end
