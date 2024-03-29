using Distributed
using Plots
# addprocs(4)  # start 4 worker processes
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
@everywhere times = Vector{Float32}()

@everywhere function stress_test(order_info_lst, id)
    global ob, times
    # generate random orders
    running_time = @elapsed for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size, 10011)
    end
    push!(times, running_time)
end


function split_array(arr, n)
    len = length(arr)
    sub_len = div(len, n)  # integer division
    subvecs = partition(arr, sub_len)
    return subvecs
end



function time_n_num_orders_testing(num_procs, NUM_ORDER_PLACED_ARRAY)
    
    
    time_20_proc_max_array = Vector{Float32}()
    time_20_proc_avg_array = Vector{Float32}()
    time_sing_proc_array = Vector{Float32}()
    num_order_array = Vector{Int64}()

    for num_order in NUM_ORDER_PLACED_ARRAY
        order_info_lst = take(lmt_order_info_iter,Int64(num_order)) |> collect
        # println("NUM_ORDER_PLACED: ", num_order)
        begin # this is the 20 process completation time
            num_procs_to_open = num_procs + (num_order % num_procs == 0 ? 0 : 1)
            addprocs(num_procs_to_open; exeflags=`--project=$(Base.active_project())`)

            global ob, times
            ob = MyLOBType()
            times = Vector{Float32}()
            splited_array = split_array(order_info_lst, num_procs) |> collect
            processes = Dict{Any, Any}()
            local array_idx = 1
            for id in workers()
                # println("workers: ", id, "\tarray_indx: ", array_idx)
                tmp = array_idx
                task = @async stress_test(splited_array[tmp], id)
                processes[task] = id
                array_idx += 1
            end
            for (key, val) in processes
                fetch(key)
                # rmprocs(val,waitfor=0)
                rmprocs(val)
            end
            max_time = maximum(times)
            average_time = sum(times) / length(times)
            # begin
            #     for time_sing in times
            #         println(time_sing)
            #     end
            #     println("length: ", length(times))
            #     println("Maximum: ", max_time)
            #     println("Average: ", average_time)
            #     println(ob)
            # end
        end

        begin # this is the single process completation time
            ob_sing = MyLOBType() #Initialize empty book
            t_single = @elapsed begin
                for (orderid, price, size, side) in order_info_lst
                    submit_limit_order!(ob_sing,orderid,side,price,size, 10011)
                end
            end
            # println(ob_sing)
        end
        push!(time_20_proc_avg_array, average_time)
        push!(time_20_proc_max_array, max_time)
        push!(num_order_array, num_order)
        push!(time_sing_proc_array, t_single)
    end
    return [num_order_array, time_20_proc_max_array, time_sing_proc_array, time_20_proc_avg_array]
end

num_procs = 20
order_array = 5000 : 5000 : 10_000_00
# order_array = 5000 : 5000 : 20_000
# tuple_res = time_n_num_orders_testing(num_procs, order_array)




time_vol_array = Vector{Any}()
for cnt in 1 : 2
    time_vol_array_sing = time_n_num_orders_testing(num_procs, order_array)
    # begin
    #     local num_procs = 20
    #     local order_array = 5000 : 5000 : 20_000
    #     time_vol_array_sing = time_n_num_orders_testing(num_procs, order_array)
    #     println(time_vol_array_sing)
    # end
    push!(time_vol_array, time_vol_array_sing)
end
tuple_res = sum(time_vol_array) / length(time_vol_array)






x_array = tuple_res[1]
x_array = x_array[2 : end]
y_array_20_max_process = tuple_res[2]
y_array_20_max_process = y_array_20_max_process[2 : end]
y_array_sing_process = tuple_res[3]
y_array_sing_process = y_array_sing_process[2 : end]
y_array_20_avg_process = tuple_res[4]
y_array_20_avg_process = y_array_20_avg_process[2 : end]


scatter(x_array, y_array_20_max_process, label="Actual performance across 20 concurrent processes", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_sing_process, label="Actual performance on single process", mc=:white, msc=colorant"#375CD9", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Orders Placed", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)

# savefig("test/fig/stress_test_conc_20_pro_act_fig_all.pdf")
folder_name = "stress_test_conc_20_pro"
file_name = "stress_test_conc_20_pro_act_fig_all"

mkdir("test/fig/$(folder_name)")
savefig("test/fig/$(folder_name)/$(file_name)_fig.pdf")



scatter(x_array, y_array_20_max_process, label="Actual performance across 20 concurrent processes", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Orders Placed", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)

# savefig("test/fig/stress_test_conc_20_pro_act_fig_partial.pdf")
file_name = "stress_test_conc_20_pro_act_fig_partial"

savefig("test/fig/$(folder_name)/$(file_name)_fig.pdf")


scatter(x_array, y_array_20_avg_process, label="Average performance across 20 concurrent processes", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
scatter!(x_array, y_array_sing_process, label="Average performance on single process", mc=:white, msc=colorant"#375CD9", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Orders Placed", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)

# savefig("test/fig/stress_test_conc_20_pro_avg_fig_all.pdf")

file_name = "stress_test_conc_20_pro_avg_fig_all"


savefig("test/fig/$(folder_name)/$(file_name)_fig.pdf")




scatter(x_array, y_array_20_avg_process, label="Average performance across 20 concurrent processes", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Orders Placed", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)

# savefig("test/fig/stress_test_conc_20_pro_avg_fig_partial.pdf")

file_name = "stress_test_conc_20_pro_avg_fig_partial"

savefig("test/fig/$(folder_name)/$(file_name)_fig.pdf")


write_io("test/fig/$(folder_name)/$(file_name)_x.txt", x_array)
write_io("test/fig/$(folder_name)/$(file_name)_y_array_20_max_process.txt", y_array_20_max_process)
write_io("test/fig/$(folder_name)/$(file_name)_y_array_sing_process.txt", y_array_sing_process)
write_io("test/fig/$(folder_name)/$(file_name)_y_array_20_avg_process.txt", y_array_20_avg_process)

# include("test/stress_test_conc_20_pro_act_fig.jl")