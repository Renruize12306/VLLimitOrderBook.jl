using VL_LimitOrderBook
using Dates
using Base.Iterators: zip,cycle,take,filter

# THIS SIMULATES BROKER/CLIENT SENDING AND RECEIVING ORDER
# include("test/test2.jl")

# Create (Deterministic) Limit Order Generator
MyUOBType = UnmatchedOrderBook{Float64, Float64, Int64, Int64, DateTime, String, Integer} # define types for Order Size, Price, Transcation ID, Account ID, Order Creation Time, IP Address, Port
MyLOBType = OrderBook{Float64, Float64, Int64, Int64} # define types for Order Size, Price, Order IDs, Account IDs
ob = MyLOBType() # Initialize empty order book
uob = MyUOBType() # Initialize unmatched book process

orderid_iter = Base.Iterators.countfrom(1)
sign_iter = cycle([1,-1,1,-1])
side_iter = ( s > 0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
spread_iter = cycle([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]*1e-2)
price_iter = ( Float32(99.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
size_iter = cycle([10, 11, 20, 21, 30, 31, 40, 41, 50, 51])

# zip them all together
lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)

order_info_lst = take(lmt_order_info_iter,6)

for (orderid, price, size, side) in order_info_lst
    submit_limit_order!(ob,uob,orderid,side,price,size,10101)
    print(orderid, ' ',side,' ',price,'\n')
end

# Simple order submission examples

# limit order
# submit_limit_order!(ob,uob,10000,SELL_ORDER,99.0,5,10101)
# submit_limit_order!(ob,uob,10000,BUY_ORDER,100,5,10101)

# market order
# submit_market_order!(ob, BUY_ORDER, 5)

# market order by funds
#   if OrderSize::Int64
# submit_market_order_byfunds!(ob, BUY_ORDER, 5.0) # match nothing and return back $5
# submit_market_order_byfunds!(ob, BUY_ORDER, 100.0) # match 1 share and return back ~$0.99
#   if OrderSize::Float64
# submit_market_order_byfunds!(ob, BUY_ORDER, 5.0) # match ~0.05 shares
# submit_market_order_byfunds!(ob, BUY_ORDER, 100.0) # match ~1.01 shares

# cancel order
# submit_limit_order!(ob, uob, 111, SELL_ORDER, 99.009, 20, 101111)
# cancel_order!(ob, 111, SELL_ORDER, 99.009)

# Additional order book functionality
# best_bid_ask(ob)
# book_depth_info(ob)
# get_acct(ob,acct_id)
# volume_bid_ask(ob::OrderBook)
# n_orders_bid_ask(ob::OrderBook)

# # Create second order book
# ob2 = MyLOBType() # Initialize empty order book
# uob2 = MyUOBType() # Initialize unmatched book process
# # fill book with random limit orders
# randspread() = ceil(-0.05*log(rand()),digits=2)
# rand_side() = rand([BUY_ORDER,SELL_ORDER])
# for i=1:10
#     # add some limit orders
#     submit_limit_order!(ob2,uob2,2i,BUY_ORDER,99.0-randspread(),rand(5:5:20),1287)
#     submit_limit_order!(ob2,uob2,3i,SELL_ORDER,99.0+randspread(),rand(5:5:20),1287)
#     if (rand() < 0.1) # and some market orders
#         submit_market_order!(ob2,rand_side(),rand(10:25:150))
#     end
# end

# ======================================================================================== #
# Fill type examples

# LIMIT ORDERS

#=
# FILLORKILL_FILLTYPE

# BUY_ORDER
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99, 60, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 60, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 15, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 5, 101111, FILLORKILL_FILLTYPE) # 5 matched
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.020, 15, 101111, FILLORKILL_FILLTYPE) # 15 matched

# SELL_ORDER
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 80, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 1, 101111, FILLORKILL_FILLTYPE) # 1 matched
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.981, 15, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.980, 15, 101111, FILLORKILL_FILLTYPE) # 15 matched
=#

#=
# IMMEDIATEORCANCEL_FILLTYPE

# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# match other below order, the other disregard
# BUY_ORDER
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.011, 5, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.011, 15, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_limit_order!(ob,uob, 111, BUY_ORDER,100, 1, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 1 matched
# submit_limit_order!(ob,uob, 111, BUY_ORDER,100, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 49 matched

# SELL_ORDER
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.985, 1, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 1 matched
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.985, 15, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 10 matched
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 10, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 10 matched
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 45, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 42 matched
=#

# Default fill type
#=
# VANILLA_FILLTYPE

# submit_limit_order!(ob,uob, 111, BUY_ORDER, 98.991, 20, 101111) # add to bid book 20
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 99.009, 20, 101111) # add to ask book 20


# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.011, 5, 101111) # matched ASK 5
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.011, 20, 101111) # matched ASK 20
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.025, 50, 101111) # matched ASK 25, add Bid 25

# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.985, 46, 101111) # matched BID 46
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.985, 15, 101111) # matched BID 10, add Ask 5
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 55, 101111) # matched BID 52, add Ask 3
=#


# MARKET ORDERS

#=
# IMMEDIATEORCANCEL_FILLTYPE

# BUYSIDE
# submit_market_order!(ob, BUY_ORDER, 5, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_market_order!(ob, BUY_ORDER, 30, IMMEDIATEORCANCEL_FILLTYPE) # 30 matched
# submit_market_order!(ob, BUY_ORDER, 100, IMMEDIATEORCANCEL_FILLTYPE) # 25 matched

# SELLSIDE
# submit_market_order!(ob, SELL_ORDER, 5, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_market_order!(ob, SELL_ORDER, 28, IMMEDIATEORCANCEL_FILLTYPE) # 28 matched
# submit_market_order!(ob, SELL_ORDER, 100, IMMEDIATEORCANCEL_FILLTYPE) # 30 matched
=#

#=
# FILLORKILL_FILLTYPE

# BUYSIDE
# submit_market_order!(ob, BUY_ORDER, 5, FILLORKILL_FILLTYPE) # 5 matched
# submit_market_order!(ob, BUY_ORDER, 30, FILLORKILL_FILLTYPE) # 30 matched
# submit_market_order!(ob, BUY_ORDER, 100, FILLORKILL_FILLTYPE) # 0 matched

# SELLSIDE
# submit_market_order!(ob, SELL_ORDER, 5, FILLORKILL_FILLTYPE) # 5 matched
# submit_market_order!(ob, SELL_ORDER, 28, FILLORKILL_FILLTYPE) # 28 matched
# submit_market_order!(ob, SELL_ORDER, 100, FILLORKILL_FILLTYPE) # 0 matched
=#

#=
# ALLORNONE_FILLTYPE testing

# BUY_ORDER
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99, 60, 101111, ALLORNONE_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 60, 101111, ALLORNONE_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 15, 101111, ALLORNONE_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 5, 101111, ALLORNONE_FILLTYPE) # 5 matched
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.020, 15, 101111, ALLORNONE_FILLTYPE) # 15 matched

# SELL_ORDER
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 80, 101111, ALLORNONE_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 96, 1, 101111, ALLORNONE_FILLTYPE) # 1 matched
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.981, 15, 101111, ALLORNONE_FILLTYPE) # nothing changed
# submit_limit_order!(ob,uob, 111, SELL_ORDER, 98.980, 15, 101111, ALLORNONE_FILLTYPE) # 15 matched
=#

# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.012, 5, 101111, FILLORKILL_FILLTYPE) # 5 matched
# submit_limit_order!(ob,uob, 111, BUY_ORDER, 99.020, 15, 101111, FILLORKILL_FILLTYPE) # 15 matched