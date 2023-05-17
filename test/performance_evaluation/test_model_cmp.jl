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
    spread_iter = cycle([3 2 3 2 2 2 3 2 3 4 2 2 1 2 4 5 6 4 9 5 3 2 3 2 3 3 2 2 3 2 5 2 2 2 2 2 4 2 3 6 5 6 3 2 3 5 4])
    price_iter = ( Float32(1000 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
    size_iter = cycle([2, 9, 5, 3, 3, 4, 10, 15, 1, 6, 13, 11, 4, 1, 5, 1, 3, 7, 9, 11, 13, 17, 19, 21, 27, 9, 103,])
    # zip them all together
    user_id = Base.Iterators.countfrom(1)
    lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter,user_id)
end

function time_n_vol_upper_limit(uppder_limit::Int)
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,Int64(uppder_limit)) |> collect
    t = @elapsed begin
        for (orderid, price, size, side, user_id) in order_info_lst
            submit_limit_order!(ob,orderid,side,price,size, user_id)
        end
    end
    return t
end

function time_n_vol_group_testing(test_sample)
    times = Vector{Float32}()
    vols = Vector{Int64}()
    cnt = 0
    for i in test_sample
        t = time_n_vol_upper_limit(i)
        cnt += 1
        if cnt == 1
            continue
        end
        
        # println("Order Volumes in all levels: ", i)
        push!(times, t)
        push!(vols, i)
    end
    return [vols,times]
end


# time_vol = time_n_vol_group_testing(10_000_000)

time_vol_array = Vector{Any}()
for cnt in 1 : 5
    test_sample = [2500, 5000, 10000, 15000, 20000, 25000, 30000]
    time_vol_array_sing = time_n_vol_group_testing(test_sample)
    # time_vol_array_sing = time_n_vol_group_testing(5000, 25000)
    # println(time_vol_array_sing)
    push!(time_vol_array, time_vol_array_sing)
end
time_vol = sum(time_vol_array) / length(time_vol_array)



x_array = time_vol[1]
y_array = time_vol[2]


scatter(x_array, y_array, label="Performance", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Limit Orders Placed", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)

file_name = "insert_cmp_jl"

mkdir("test/fig/$(file_name)")
savefig("test/fig/$(file_name)/$(file_name)_fig.pdf")

write_io("test/fig/$(file_name)/$(file_name)_x.txt", x_array)
write_io("test/fig/$(file_name)/$(file_name)_y.txt", y_array)

# include("test/test_model_cmp.jl")