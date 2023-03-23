using BenchmarkTools
using AVLTrees
using VLLimitOrderBook
using Base.Iterators: zip,cycle,take,filter, flatten
using Dates
using Plots

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

function market_order_submission_group_testing_upper_limit(uppder_limit::Int)
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,Int64(uppder_limit)) |> collect
    begin
        for (orderid, price, size, side) in order_info_lst
            submit_limit_order!(ob,orderid,side,price,size, 10011)
        end
        mkt_order_submit_vol = uppder_limit/5
        t1 = @elapsed submit_market_order!(ob,SELL_ORDER, 1)
        t2 = t1 + ( @elapsed submit_market_order!(ob,SELL_ORDER, mkt_order_submit_vol) ) 
        t3 = t2 + ( @elapsed submit_market_order!(ob,SELL_ORDER, mkt_order_submit_vol) ) 
        t4 = t3 + ( @elapsed submit_market_order!(ob,SELL_ORDER, mkt_order_submit_vol) )
        t5 = t4 + ( @elapsed submit_market_order!(ob,SELL_ORDER, mkt_order_submit_vol) )
        t6 = t5 + ( @elapsed submit_market_order!(ob,SELL_ORDER, mkt_order_submit_vol - 1) )
    end
    return t1, t2, t3, t4, t5, t6
end

function market_order_submission_group_testing(start::Int, last::Int)
    times_single = Vector{Float32}()
    times_ratio_1 = Vector{Float32}()
    times_ratio_2 = Vector{Float32}()
    times_ratio_3 = Vector{Float32}()
    times_ratio_4 = Vector{Float32}()
    times_ratio_5 = Vector{Float32}()
    vols = Vector{Int64}()
    # for i in start : 2000 : last
    for i in start : 10000 : last
        tuple = market_order_submission_group_testing_upper_limit(i)
        if i == start
            continue
        end
        
        push!(vols, i)
        push!(times_single, tuple[1])
        push!(times_ratio_1, tuple[2])
        push!(times_ratio_2, tuple[3])
        push!(times_ratio_3, tuple[4])
        push!(times_ratio_4, tuple[5])
        push!(times_ratio_5, tuple[6])

    end
    return (vols,
    times_single, 
    times_ratio_1,
    times_ratio_2,
    times_ratio_3,
    times_ratio_4,
    times_ratio_5)
end


time_vol = market_order_submission_group_testing(5000, 10_000_00)
x_array = time_vol[1]
y_array_single = time_vol[2]
y_array_ratio_1 = time_vol[3]
y_array_ratio_2 = time_vol[4]
y_array_ratio_3 = time_vol[5]
y_array_ratio_4 = time_vol[6]
y_array_ratio_5 = time_vol[7]
scatter(x_array, y_array_single, label="put one mkt order one side", mc=:white, msc=colorant"#1A1615", legend=:topleft, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_ratio_1, label="put 20% mkt order one side", mc=:white, msc=colorant"#375CD9", legend=:topleft, markershape=:star5,
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_ratio_2, label="put 40% mkt order one side", mc=:white, msc=colorant"#A83E32", legend=:topleft, markershape=:heptagon,
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_ratio_3, label="put 60% mkt order one side", mc=:white, msc=colorant"#2E5C10", legend=:topleft, markershape=:dtriangle,
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_ratio_4, label="put 80% mkt order one side", mc=:white, msc=colorant"#4F105C", legend=:topleft, markershape=:diamond,
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_ratio_5, label="put 100% mkt order one side", mc=:white, msc=colorant"#ADB002", legend=:topleft, markershape=:octagon,
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Limit Orders Placed", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)
