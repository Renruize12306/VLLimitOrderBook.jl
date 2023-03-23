using Distributed
# addprocs(4)  # start 4 worker processes
addprocs(4; exeflags=`--project=$(Base.active_project())`)


@everywhere using VLLimitOrderBook
@everywhere using Base.Iterators: zip,cycle,take,filter, flatten, partition


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

@everywhere ob = MyLOBType()

@everywhere function stress_test(ob, order_info_lst)
    
    # generate random orders
    @time for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size, 10011)
    end
    println(ob)
end



@everywhere function stress_test_wrapper(orderbook, splited_array)
    stress_test(orderbook, splited_array)
end

@everywhere function split_array(arr, n)
    len = length(arr)
    sub_len = div(len, n)  # integer division
    subvecs = partition(arr, sub_len)
    return subvecs
end

@everywhere order_info_lst = take(lmt_order_info_iter,Int64(10)) |> collect

@everywhere splited_array = split_array(order_info_lst, 3) |> collect

for array in splited_array[1]
    println(array)
end


m = pmap(id -> @spawnat(id, stress_test_wrapper(ob, splited_array[1])), workers())
