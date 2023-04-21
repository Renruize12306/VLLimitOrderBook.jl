using VLLimitOrderBook
using JSON, HTTP
using Dates

function process_msg(msg, mod::Int)
    try 
        type = msg["type"]
        #=
            type of messages
            0 -- submit limit order
            1 -- submit market order
        =#
        # println(msg)
        order_side_converted = msg["order_side"] > 0 ? SELL_ORDER : BUY_ORDER
        if type == "0"
            submit_limit_order!(ob, msg["order_id"], order_side_converted, msg["order_price"], msg["order_size"], msg["mpid"])
        elseif type == "1"
            submit_market_order!(ob, order_side_converted, msg["volume"])
        end
    catch error
        error_message = sprint(showerror, error, catch_backtrace())
        vl_error_obj = ErrorException(error_message)
        throw(vl_error_obj)
    end
end

function server_single_run(mod::Int)
    try
        vector_res = Vector{Any}()

        println("Server started....")
        server = HTTP.WebSockets.listen!("0.0.0.0", 8081) do ws
            cnt = 1
            time_start = Int(time_ns())
            for msg in ws
                if length(msg) > 0
                    ds = JSON.parse(msg)
                    process_msg(ds, mod)
                    cnt += 1
                    if cnt % mod == 0
                        # println(msg)
                        time_stop = Int(time_ns())
                        push!(vector_res, time_stop - time_start)
                    end
                end
            end
        end
        return server, vector_res
    catch error
        error_message = sprint(showerror, error, catch_backtrace())
        vl_error_obj = ErrorException(error_message)
        throw(vl_error_obj)
    end
end

MyOrderSubTypes = (Int64,Float32,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
MyOrderType = Order{MyOrderSubTypes...}
MyLOBType = OrderBook{MyOrderSubTypes...}

ob = MyLOBType()

function write_io(file_name::String, data_vector::Vector)
    io = open(file_name, "w");
    for data in data_vector
        # println(data)
        write(io, string(data) * "\n")
    end
    close(io)
end




function dump_file(time_rec_vec::Vector)
    time_rec_vec = time_rec_vec .- time_rec_vec[1]
    time_rec_vec = time_rec_vec[2 : end]
    write_io("test/figures_input/server_client/data/time_rec_vec.txt", time_rec_vec)
    println("finished writing server")
end

server, time_rec_vec = server_single_run(1000)


# include("test/figures_input/server_client/talking_test_server.jl")
# close(server)
# dump_file(time_rec_vec)

