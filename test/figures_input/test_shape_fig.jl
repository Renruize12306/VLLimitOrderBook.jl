using AVLTrees
using VLLimitOrderBook
using Base.Iterators: zip,cycle,take,filter, flatten
using Dates
using Plots


function define_shape(n::Int)
    spread_vector = Vector{Int}()
    for i in 1 : n
        push!(spread_vector, i)
        push!(spread_vector, i)
    end
    spread_iter = cycle(spread_vector*1e-2)
    return spread_iter
end

begin # Create (Deterministic) Limit Order Generator
    MyOrderSubTypes = (Int64,Float32,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
    MyOrderType = Order{MyOrderSubTypes...}
    MyLOBType = OrderBook{MyOrderSubTypes...}
end

function define_shape_spread(shape::Int) 
    orderid_iter = Base.Iterators.countfrom(1)
    sign_iter = cycle([1,-1,1,-1,1,-1])
    side_iter = ( s > 0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
    spread_iter = define_shape(shape)
    price_iter = ( Float32(100_000.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
    size_iter = cycle([2, 9, 5, 3, 3, 4, 10, 15, 1, 6, 13, 11, 4, 1, 5, 1, 3, 7, 9, 11, 13, 17, 19, 21, 27, 2,3,4,67,21,45])
    # zip them all together
    lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)
    return lmt_order_info_iter
end

function test_shape(uppder_limit::Int, spread::Int)
    lmt_order_info_iter = define_shape_spread(spread)
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,Int64(uppder_limit)) |> collect
    t = @elapsed begin
        for (orderid, price, size, side) in order_info_lst
            submit_limit_order!(ob,orderid,side,price,size, 10011)
        end
    end
    # show(ob)
    return t, ob
end

# t, ob = test_shape(30, 2)

function test_shape_time_function(order_upper_bound::Int, shape_upper_bound::Int)
    shapes = 1 : 5000 : shape_upper_bound
    # shapes = shape_upper_bound : shape_upper_bound

    shape_vec = Vector{Any}()
    time_vec = Vector{Any}()
    # ob_vec = Vector{Any}()
    for shape_single in shapes
        println("Shape\t", shape_single)
        t, ob = test_shape(order_upper_bound, shape_single)
        push!(shape_vec, shape_single)
        push!(time_vec,t)
        # println(ob)
    end
    return [shape_vec, time_vec]
end

# time_shape_array_sing = test_shape_time_function(30, 3)


time_shape_array = Vector{Any}()
for cnt in 1 : 5
# for cnt in 1 : 1
    # time_shape_array_sing = test_shape_time_function(1000_000, 1000_000)
    time_shape_array_sing = test_shape_time_function(1000_000, 16000)
    
    push!(time_shape_array, time_shape_array_sing)
end
time_shape = sum(time_shape_array) / length(time_shape_array)

x_array = time_shape[1]
x_array = x_array[2 : end]
y_array = time_shape[2]
y_array = y_array[2 : end]

scatter(x_array, y_array, label="Performance", mc=:white, msc=colorant"#375CD9", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Shape of Limit Order Book", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)


dir_name = "test_shape_fig"

mkdir("test/fig/$(file_name)")
savefig("test/fig/$(file_name)/$(file_name)_fig.png")

write_io("test/fig/$(file_name)/$(file_name)_x.txt", x_array)
write_io("test/fig/$(file_name)/$(file_name)_y.txt", y_array)
# include("test/test_shape.jl")