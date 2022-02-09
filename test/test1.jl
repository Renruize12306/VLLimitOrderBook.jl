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
# submit_limit_order!(ob, 111, BUY_ORDER, 99, 60, 101111, FILLORKILL_FILLTYPE) nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 60, 101111, FILLORKILL_FILLTYPE) error


# IMMEDIATEORCANCEL_FILLTYPE

# submit_limit_order!(ob, 111, BUY_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, BUY_ORDER, 99.012, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE)
# match other below order, the other disregard

# submit_limit_order!(ob, 111, SELL_ORDER, 99, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed
# submit_limit_order!(ob, 111, SELL_ORDER, 98.988, 60, 101111, IMMEDIATEORCANCEL_FILLTYPE) # nothing changed

# submit_limit_order!(ob,10000,BUY_ORDER,100,1.2,10101)
# submit_limit_order!(ob,10000,BUY_ORDER,100,1,10101)
