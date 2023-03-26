module VLLimitOrderBook
using AVLTrees: AVLTree
using Base: @kwdef
using Printf
include("orderqueue.jl")
include("sidebook.jl")
include("book.jl")
include("ordermatching.jl")
export BUY_ORDER, SELL_ORDER, VANILLA_FILLTYPE, IMMEDIATEORCANCEL_FILLTYPE, FILLORKILL_FILLTYPE, ALLORNONE_FILLTYPE, ALLOW_LOCKING
export OrderBook, Order, OrderTraits, AcctMap, OrderSide
export submit_limit_order!,
    cancel_order!,
    cancel_partial_order!,
    submit_market_order!,
    submit_market_order_byfunds!,
    clear_book!,
    check_market_order_priority_with_order_id!,
    raise_priorty_via_display_property!,
    reduce_priorty_via_display_property!,
    elevate_priority!,
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
