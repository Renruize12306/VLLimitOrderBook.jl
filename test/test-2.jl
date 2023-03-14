using BenchmarkTools
using AVLTrees
using Base.Iterators: zip,cycle,take,filter, flatten
using Dates
begin # Create (Deterministic) Limit Order Generator
    MyOrderSubTypes = (Int64,Float32,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
    MyOrderType = Order{MyOrderSubTypes...}
    MyLOBType = OrderBook{MyOrderSubTypes...}
    orderid_iter = Base.Iterators.countfrom(1)
    sign_iter = cycle([1,-1,-1,1,1,-1])
    side_iter = ( s>0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
    spread_iter = cycle([3 2 3 2 2 2 3 2 3 4 2 2 1 2 4 5 6 4 9 5 3 2 3 2 3 3 2 2 3 2 5 2 2 2 2 2 4 2 3 6 5 6 3 2 3 5 4]*1e-2)
    price_iter = ( Float32(100.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
    size_iter = cycle([2, 9, 5, 3, 3, 4, 10, 15, 1, 6, 13, 11, 4, 1, 5, 1, 3, 7, 9, 11, 13, 17, 19, 21, 27, 9, 103,])
    # zip them all together
    lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)
    user_id = 10011
end

output = open(pwd()*"/test/test-2_output.txt", "w");

function output_io(output, bcmk ,output_source)
    write(output, "\nSource:\t" * output_source * "\n\n")
    Base.show(output,"text/plain", bcmk)
    write(output, "\n")
end

ob = MyLOBType() #Initialize empty book
order_info_lst = take(lmt_order_info_iter,Int64(10_000_000)) |> collect
for (orderid, price, size, side) in order_info_lst
    submit_limit_order!(ob,orderid,side,price,size, 10011)
end

(orderid, price, size, side), _ =  Iterators.peel(lmt_order_info_iter)
bcmk = @benchmark submit_limit_order!($ob,$orderid,$side,$price,$size,10011)
output_io(output, bcmk ,"insert one limit order")
bcmk = @benchmark submit_market_order!($ob,SELL_ORDER, 50_000_0)
output_io(output, bcmk ,"insert 50_000_0 market order")


ob = MyLOBType() # initialize order book
# fill book with random limit orders
randspread() = ceil(-0.03*log(rand()),digits=2)
for i=1:1000
    submit_limit_order!(ob,2i,BUY_ORDER,99.0-randspread(),rand(1:25),10011)
    submit_limit_order!(ob,3i,SELL_ORDER,99.0+randspread(),rand(1:25),10011)
end

bcmk = @benchmark submit_limit_order!(ob,$2,$(rand([BUY_ORDER, SELL_ORDER])),$(99.0+rand([1,-1])*randspread()),$(rand(1:25)),10011)
output_io(output, bcmk ,"ramdom submit order")
