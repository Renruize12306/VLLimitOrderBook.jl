# VANILLA_FILLTYPE √

# IMMEDIATEORCANCEL_FILLTYPE √

# submit_limit_order!(ob, 111, BUY_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE)
# match other below order, the other disregard

# submit_limit_order!(ob, 111, SELL_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, SELL_ORDER, 98.988, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed

# FILLORKILL_FILLTYPE

# submit_limit_order!(ob, 111, BUY_ORDER, 99, 60, 101111, FILLORKILL_FILLTYPE) nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 60, 101111, FILLORKILL_FILLTYPE) error

import VL_LimitOrderBook
using VL_LimitOrderBook, Random
using Test
using Base.Iterators: zip,cycle,take,filter

MyLOBType = OrderBook{Int64, Float32, Int64, Int64}
ob = MyLOBType()

orderid_iter = Base.Iterators.countfrom(1)
sign_iter = cycle([1,-1,1,-1])
side_iter = ( s > 0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
spread_iter = cycle([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]*1e-2)
price_iter = ( Float32(99.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
size_iter = cycle([10, 11, 20, 21, 30, 31, 40, 41, 50, 51])

lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)

order_info_lst = take(lmt_order_info_iter,12)
# Add a bunch of orders
for (orderid, price, size, side) in order_info_lst
    submit_limit_order!(ob,orderid,side,price,size,10101)
end
for (orderid, price, size, side) in order_info_lst
    print(orderid, ' ',side,' ',price,'\n')
    cancel_order!(ob,orderid,side,price)
end

order_info_lst = take(lmt_order_info_iter,6)

# order_lst_tmp = Base.Iterators.take( Base.Iterators.filter( x-> x[4]===BUY_ORDER, order_info_lst), 3 ) |> collect

for (orderid, price, size, side) in order_info_lst
    submit_limit_order!(ob,orderid,side,price,size,10101)
end
# submit_limit_order!(ob,10000,BUY_ORDER,98.99,5,10101)
# submit_limit_order!(ob,10000,SELL_ORDER,99.01,5,10101)

# submit_limit_order!(ob,10000,BUY_ORDER,99.011,13,10101)
# submit_limit_order!(ob,10000,SELL_ORDER,100,4,10101)

# submit_limit_order!(ob,10000,BUY_ORDER,99.11,70,10101)
# ubmit_limit_order!(ob, 10009, SELL_ORDER, 97, 3, 10101)
# submit_limit_order!(ob,10000,BUY_ORDER,100,70,10101)

# mo_matches, mo_ltt = submit_market_order!(ob, SELL_ORDER, 70)
# mo_matches, mo_ltt = submit_market_order!(ob, SELL_ORDER, 150)
# mo_matches, mo_ltt = submit_market_order!(ob, BUY_ORDER, 150)
# submit_market_order!(ob, BUY_ORDER, 13)
# ob
# mo_matches
# mo_ltt

io = open("log.csv", "w");
write_csv(io,ob)


# FILLORKILL_FILLTYPE
# BUY_ORDER
# submit_limit_order!(ob, 111, BUY_ORDER, 99, 60, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 60, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 15, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 5, 101111, FILLORKILL_FILLTYPE) # 5 matched
# submit_limit_order!(ob, 111, BUY_ORDER, 99.020, 15, 101111, FILLORKILL_FILLTYPE) # 15 matched

# SELL_ORDER
# submit_limit_order!(ob, 111, SELL_ORDER, 96, 80, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, SELL_ORDER, 96, 1, 101111, FILLORKILL_FILLTYPE) # 1 matched
# submit_limit_order!(ob, 111, SELL_ORDER, 98.981, 15, 101111, FILLORKILL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, SELL_ORDER, 98.980, 15, 101111, FILLORKILL_FILLTYPE) # 15 matched


# IMMEDIATEORCANCEL_FILLTYPE

# submit_limit_order!(ob, 111, BUY_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# match other below order, the other disregard
# BUY_ORDER
# submit_limit_order!(ob, 111, BUY_ORDER, 99.011, 5, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_limit_order!(ob, 111, BUY_ORDER, 99.011, 15, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_limit_order!(ob, 111, BUY_ORDER,100, 1, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 1 matched
# submit_limit_order!(ob, 111, BUY_ORDER,100, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 49 matched


# SELL_ORDER
# submit_limit_order!(ob, 111, SELL_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, SELL_ORDER, 98.985, 1, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 1 matched
# submit_limit_order!(ob, 111, SELL_ORDER, 98.985, 15, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 10 matched
# submit_limit_order!(ob, 111, SELL_ORDER, 96, 10, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 10 matched
# submit_limit_order!(ob, 111, SELL_ORDER, 96, 45, 101111, IMMEDIATEORCANCEL_FILLTYPE) # 42 matched


# Default fill type
# submit_limit_order!(ob, 111, BUY_ORDER, 98.991, 20, 101111) # add to bid book 20
# submit_limit_order!(ob, 111, SELL_ORDER, 99.009, 20, 101111) # add to ask book 20


# submit_limit_order!(ob, 111, BUY_ORDER, 99.011, 5, 101111) # matched ASK 5
# submit_limit_order!(ob, 111, BUY_ORDER, 99.011, 20, 101111) # matched ASK 20
# submit_limit_order!(ob, 111, BUY_ORDER, 99.025, 50, 101111) # matched ASK 25, add Bid 25

# submit_limit_order!(ob, 111, SELL_ORDER, 98.985, 46, 101111) # matched BID 46
# submit_limit_order!(ob, 111, SELL_ORDER, 98.985, 15, 101111) # matched BID 10, add ask 5
# submit_limit_order!(ob, 111, SELL_ORDER, 96, 55, 101111) # matched BID 52, add ask 3


# submit_limit_order!(ob, 111, SELL_ORDER, 99.009, 20, 101111)
# cancel_order!(ob, 111, SELL_ORDER, 99.009)
# submit_limit_order!(ob, 111, SELL_ORDER, 98.985, 1, 101111, IMMEDIATEORCANCEL_FILLTYPE)
# cancel_order!(ob, 111, SELL_ORDER, 98.985)

# cancel_order!(ob, 1, SELL_ORDER, 99.01)






# market order
# include("test/FillType/test1.jl")
# BUYSIDE
# submit_market_order!(ob, BUY_ORDER, 5) # 5 matched
# submit_market_order!(ob, BUY_ORDER, 30) # 30 matched
# submit_market_order!(ob, BUY_ORDER, 100) # 25 matched
# SELLSIDE
# submit_market_order!(ob, SELL_ORDER, 5) # 5 matched
# submit_market_order!(ob, SELL_ORDER, 28) # 28 matched
# submit_market_order!(ob, SELL_ORDER, 100) # 30 matched

# IMMEDIATEORCANCEL_FILLTYPE
# BUYSIDE
# submit_market_order!(ob, BUY_ORDER, 5, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_market_order!(ob, BUY_ORDER, 30, IMMEDIATEORCANCEL_FILLTYPE) # 30 matched
# submit_market_order!(ob, BUY_ORDER, 100, IMMEDIATEORCANCEL_FILLTYPE) # 25 matched
# SELLSIDE
# submit_market_order!(ob, SELL_ORDER, 5, IMMEDIATEORCANCEL_FILLTYPE) # 5 matched
# submit_market_order!(ob, SELL_ORDER, 28, IMMEDIATEORCANCEL_FILLTYPE) # 28 matched
# submit_market_order!(ob, SELL_ORDER, 100, IMMEDIATEORCANCEL_FILLTYPE) # 30 matched


# FILLORKILL_FILLTYPE
# BUYSIDE
# submit_market_order!(ob, BUY_ORDER, 5, FILLORKILL_FILLTYPE) # 5 matched
# submit_market_order!(ob, BUY_ORDER, 30, FILLORKILL_FILLTYPE) # 30 matched
# submit_market_order!(ob, BUY_ORDER, 100, FILLORKILL_FILLTYPE) # 0 matched
# SELLSIDE
# submit_market_order!(ob, SELL_ORDER, 5, FILLORKILL_FILLTYPE) # 5 matched
# submit_market_order!(ob, SELL_ORDER, 28, FILLORKILL_FILLTYPE) # 28 matched
# submit_market_order!(ob, SELL_ORDER, 100, FILLORKILL_FILLTYPE) # 0 matched
