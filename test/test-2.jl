import Pkg;
Pkg.add("BenchmarkTools")
using BenchmarkTools
# Add a bunch of orders

ob = MyLOBType() #Initialize empty book
order_info_lst = take(lmt_order_info_iter,Int64(10_000)) |> collect
for (orderid, price, size, side) in order_info_lst
    submit_limit_order!(ob,orderid,side,price,size, 10011)
end

(orderid, price, size, side), _ =  Iterators.peel(lmt_order_info_iter)
@benchmark submit_limit_order!($ob,$orderid,$side,$price,$size,10011)
@benchmark (submit_market_order!($ob,BUY_ORDER,1000);)

@code_typed submit_limit_order!(ob,orderid,side,price,size,10011)


ob = MyLOBType() # initialize order book
# fill book with random limit orders
randspread() = ceil(-0.03*log(rand()),digits=2)
for i=1:1000
    submit_limit_order!(ob,2i,BUY_ORDER,99.0-randspread(),rand(1:25),10011)
    submit_limit_order!(ob,3i,SELL_ORDER,99.0+randspread(),rand(1:25),10011)
end

@benchmark submit_limit_order!(ob,$2,$(rand([BUY_ORDER,SELL_ORDER])),$(99.0+rand([1,-1])*randspread()),$(rand(1:25)),10011)
