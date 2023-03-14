using VLLimitOrderBook, Test, BenchmarkTools

begin 
    # orderbook initialization
    MyOrderSubTypes = (Int64,Float32,Int64,Any)
    MyOrderType = Order{MyOrderSubTypes...}
    MyLOBType = OrderBook{MyOrderSubTypes...}

    function process_message_string(line::String)::Dict{String, Any}
        arr = split(line, ',')
        ans = Dict{String, Any}()

        ans["timestamp"] = arr[1]
        ans["order_type"] = arr[2]

        if arr[2] == "P"
            # this is a hidden order, does not have any influence to the order book
            return ans
        end
        ans["order_id"] = parse(Int64, arr[3])
        ans["order_side"] = arr[4] == "0" ?  BUY_ORDER : SELL_ORDER
        ans["order_size"] = parse(Int64, arr[5])
        ans["order_price"] =  parse(Float32, arr[6])
        ans["cancel_size"] = ""
        ans["execute_size"] = "" 
        ans["old_order_id"] = ""
        ans["old_order_size"] = ""
        ans["old_order_price"] = ""
        ans["mpid"] = arr[12] == "" ? nothing : String(arr[12])

        if ans["order_type"] == "A"

        elseif  ans["order_type"] == "D"
            ans["cancel_size"] = parse(Int64, arr[7])
        elseif ans["order_type"] == "E"
            ans["execute_size"] = parse(Int64, arr[8])
        elseif ans["order_type"] == "C"
            ans["execute_size"] = parse(Int64, arr[8])
            ans["old_order_price"] = parse(Float32, arr[11])
        elseif ans["order_type"] == "R"
            ans["old_order_id"] = parse(Int64, arr[9])
            ans["old_order_size"] = parse(Int64, arr[10])
            ans["old_order_price"] = parse(Float32, arr[11])
        end
        return ans
    end


    function finish_queued_message(dicts, ob)
        while length(dicts) > 0
            dict = popfirst!(dicts)
            order_match_lst, shares_left = execute_with_displayed_message_first(ob, dict)
        end
    end

    function execute_with_displayed_message_first(ob, dict)
        checked_id = check_market_order_priority_with_order_id!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
        if checked_id  == 1
            # this means the order is executed as market order, the order to be 
            # executed is in the top price queue
            return order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], true)
        else
            # this means the order is also executed as market order, although the order to be executed
            # not in the first priority, it behave like this because the previous order does not 
            # matching correctly, the previous order could be all or none order traits.
    
            # Hence, we need to modify Display properties to have higher priority than the executed order
            raise_priorty_via_display_property!(ob, dict["order_id"], dict["order_side"], dict["order_price"], false)
            
            # Then submit as market order
            return order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], false)
        end
    end
    function processing_vector_of_dict_messages(ob::OrderBook, dicts_msgs::Vector{Dict{String, Any}})
        last_timestamp = ""
        last_price = 0f0
        dicts = Vector{Dict{String, Any}}()
        for dict in dicts_msgs
            if dict["timestamp"] != last_timestamp || dict["order_type"] != "C"
                finish_queued_message(dicts, ob)
            end
    
            if dict["order_type"] == "A"
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
            elseif dict["order_type"] == "D"
                if dict["order_size"] == 0
                    cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
                else
                    cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["cancel_size"])
                end
            elseif dict["order_type"] == "E"
                checked_id = check_market_order_priority_with_order_id!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
                if checked_id  == 1
                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], true)
                elseif dict["timestamp"] == last_timestamp &&  
                    dict["order_price"] == last_price && 
                    !isnothing(checked_id) && elevate_priority!(ob, checked_id, dict["order_side"], dict["order_price"])
                    reduce_priorty_via_display_property!(ob, dict["order_id"], dict["order_side"], dict["order_price"], true)
                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], false)
                else
                    raise_priorty_via_display_property!(ob, dict["order_id"], dict["order_side"], dict["order_price"], false)
                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], false)
                end
            elseif dict["order_type"] == "R"
                cancel_order!(ob, dict["old_order_id"], dict["order_side"], dict["old_order_price"])
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"], )
            elseif dict["order_type"] == "P"
    
            elseif dict["order_type"] == "C"
                cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["old_order_price"], dict["execute_size"])
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["execute_size"], dict["mpid"], ALLOW_LOCKING)
                push!(dicts, dict)
            end
            last_timestamp = dict["timestamp"]
            if dict["order_type"] != "P"
                last_price = dict["order_price"]
            end
        end
        finish_queued_message(dicts, ob)

        return ob
    end

    function testing(s::Int, n::Int, level::Int, order_messages::String)
        
        io_order_messages = open("$(order_messages)", "r");
        ob = MyLOBType()
        
        dicts_msgs = Vector{Dict{String, Any}}()
        
        # pre-processing order message, put everything into dict
        for cur in 1 : n
            line_message = readline(io_order_messages)            
            if cur == 1 
                continue
            end
    
    
            dict = process_message_string(line_message)
            push!(dicts_msgs, dict)
        end
        close(io_order_messages)

        # benchmark begins
        
        bc = @benchmarkable processing_vector_of_dict_messages($ob, $dicts_msgs)
        bcmk = run(bc, samples = 20, evals = 10);
        return ob, bcmk
    end
    function output_io(output, bcmk ,order_messages)
        write(output, "\nSource:\t" * order_messages * "\n\n")
        Base.show(output,"text/plain", bcmk)
        write(output, "\n")
    end
end

begin
    output = open(pwd()*"/test/validation/book_validation_benchmark_output.txt", "w");
    order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
    ob, bcmk = testing(1, 503954, 36, order_messages);
    output_io(output, bcmk ,order_messages)

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_INTC_message.csv"
    ob, bcmk = testing(1, 1601350, 100, order_messages);
    output_io(output, bcmk ,order_messages)

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_AAPL_message.csv"
    ob, bcmk = testing(1, 2008467, 100, order_messages);
    output_io(output, bcmk ,order_messages)
    
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_MSFT_message.csv"
    ob, bcmk = testing(1, 1854140, 100, order_messages);
    output_io(output, bcmk ,order_messages)
    
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_SPY_message.csv"
    ob, bcmk = testing(1, 4468109, 100, order_messages);
    output_io(output, bcmk ,order_messages)

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_QQQ_message.csv"
    ob, bcmk = testing(1, 4754517, 100, order_messages);
    output_io(output, bcmk ,order_messages)
    
    close(output)
end

# function foo(a::Int, b::Int)
#     return a + b
# end
# bc = @benchmarkable foo(1,3)
# run(bc)#, samples = 1);
# res = run(bc, samples = 90000, evals = 3);
