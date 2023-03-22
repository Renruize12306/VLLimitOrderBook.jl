using Distributed
# addprocs(4)  # start 4 worker processes
addprocs(4; exeflags=`--project=$(Base.active_project())`)

# @everywhere begin
#     using Pkg; Pkg.activate(@__DIR__)
#     Pkg.instantiate(); Pkg.precompile()
#   end

@everywhere using VLLimitOrderBook
@everywhere using Base.Iterators: zip,cycle,take,filter, flatten


@everywhere begin # Create (Deterministic) Limit Order Generator
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

@everywhere function stress_test(num_orders::Int, num_trades::Int)
    # create order book
    ob = MyLOBType()
    
    # generate random orders
    order_info_lst = take(lmt_order_info_iter,Int64(num_orders)) |> collect
    @time for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size, 10011)
    end
    
    # order_info_lst = take(side_iter,Int64(num_trades)) |> collect

    # # generate random trades
    # for i in order_info_lst
    #     submit_market_order!(ob,i, 1)
    # end
end


@everywhere function stress_test_wrapper(num_orders::Int, num_trades::Int)
    stress_test(num_orders, num_trades)
end

m = pmap(id->@spawnat(id, stress_test_wrapper(10_000_0, 10_000_00)), workers())
