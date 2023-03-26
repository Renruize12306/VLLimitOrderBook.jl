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



function time_n_num_process_testing(NUM_PROCESSES_ARRAY, ORDER_PLACED)
    
    order_info_lst = take(lmt_order_info_iter,Int64(ORDER_PLACED)) |> collect
    time_consume_array = Vector{Float32}()
    num_process_array = Vector{Int64}()

    for num_procs in NUM_PROCESSES_ARRAY
        num_procs_to_open = num_procs+(ORDER_PLACED % num_procs == 0 ? 0 : 1)
        addprocs(num_procs_to_open; exeflags=`--project=$(Base.active_project())`)
        global ob
        ob = MyLOBType()
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
            rmprocs(val)
        end
        average_time = sum(times) / length(times)
        # println(ob)
        push!(time_consume_array, average_time)
        push!(num_process_array, num_procs)
    end
    return [num_process_array, time_consume_array]
end

input = 1 : 20
# input = [8, 10]
# array_res = time_n_num_process_testing(input, 1_000_000)





array_res_vector = Vector{Any}()
for cnt in 1 : 5
    # local input = 1 : 4
    res_sing = time_n_num_process_testing(input, 1_000_000)
    # res_sing = time_n_num_process_testing(input, 1_000)
    # println(res_sing)
    push!(array_res_vector, res_sing)
end
array_res = sum(array_res_vector) / length(array_res_vector)






x_array = array_res[1]
x_array = x_array[2 : end]
y_array = array_res[2]
y_array = y_array[2 : end]



scatter(x_array, y_array, label="Performance", mc=:white, msc=colorant"#EF4035", legend=:best, 
bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
xlabel!("Number of Concurrent Threads)", fontsize=18)
ylabel!("Processing Time (seconds)", fontsize=18)

dir_name = "stress_test_conc_num_proc_fig"

mkdir("test/fig/$(file_name)")
savefig("test/fig/$(file_name)/$(file_name)_fig.png")

write_io("test/fig/$(file_name)/$(file_name)_x.txt", x_array)
write_io("test/fig/$(file_name)/$(file_name)_y.txt", y_array)
# include("test/stress_test_conc_num_proc_fig.jl")