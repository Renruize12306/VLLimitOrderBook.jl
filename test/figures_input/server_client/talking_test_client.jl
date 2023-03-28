using BenchmarkTools
using AVLTrees
using VLLimitOrderBook
using Base.Iterators: zip,cycle,take,filter, flatten
using Dates
using Plots
using JSON, HTTP

function limit_order_submission_upper_limit(uppder_limit::Int, mod::Int)
    json_vector = Vector{Any}()
    order_info_lst = take(lmt_order_info_iter,Int64(uppder_limit)) |> collect
    vector_time_res = Vector{Any}()
    vector_cnt_res = Vector{Any}()
    for (orderid, price, size, side) in order_info_lst
        dict_raw = Dict{String, Any}()
        dict_raw["order_id"] = orderid
        dict_raw["order_side"] = side
        dict_raw["order_price"] = price
        dict_raw["order_size"] = size
        dict_raw["mpid"] = 10011
        dict_raw["type"] = "0"
        dict_json = JSON.json(dict_raw)
        push!(json_vector, dict_json)
    end

    HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws
        cnt = 0
        time_start = now().instant.periods.value
        for json in json_vector
            HTTP.WebSockets.send(ws, json)
            cnt += 1
            if cnt % mod == 0
                # println(json)
                time_stop = now().instant.periods.value
                push!(vector_time_res, time_stop - time_start)
                push!(vector_cnt_res, cnt)
            end
        end 
    end
    return vector_time_res, vector_cnt_res
end

function write_io(file_name::String, data_vector::Vector)
    io = open(file_name, "w");
    for data in data_vector
        # println(data)
        write(io, string(data) * "\n")
    end
    close(io)
end

orderid_iter = Base.Iterators.countfrom(1)
sign_iter = cycle([1,-1,-1,1,1,-1])
spread_iter = cycle([3 2 3 2 2 2 3 2 3 4 2 2 1 2 4 5 6 4 9 5 3 2 3 2 3 3 2 2 3 2 5 2 2 2 2 2 4 2 3 6 5 6 3 2 3 5 4]*1e-2)
price_iter = ( Float32(100.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
size_iter = cycle([2, 9, 5, 3, 3, 4, 10, 15, 1, 6, 13, 11, 4, 1, 5, 1, 3, 7, 9, 11, 13, 17, 19, 21, 27, 9, 103,])
# zip them all together
lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,sign_iter)

function start_client_and_save_file(mod::Int)
   
    time_sent_vec, num_sent_res = limit_order_submission_upper_limit(1000_000, mod)
    # time_sent_vec, num_sent_res = limit_order_submission_upper_limit(100, 20)


    time_sent_vec = time_sent_vec .- time_sent_vec[1]

    # start writing output
    time_sent_vec = time_sent_vec[2 : end]
    num_sent_vec = num_sent_res[2 : end]

    write_io("test/figures_input/server_client/data/time_sent_vec.txt", time_sent_vec)
    write_io("test/figures_input/server_client/data/num_sent_vec.txt", num_sent_vec)
    println("finished writing client")
end

start_client_and_save_file(1000)
# include("test/figures_input/server_client/talking_test_client.jl")