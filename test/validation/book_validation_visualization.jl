using VLLimitOrderBook, Test, Plots

begin 
    # orderbook initialization
    MyOrderSubTypes = (Int64,Float32,Int64,Any)
    MyOrderType = Order{MyOrderSubTypes...}
    MyLOBType = OrderBook{MyOrderSubTypes...}

    function process_message_string(line::String)::Dict{String, Any}
        arr = split(line, ',')
        ans = Dict{String, Any}()

        ans["timestamp"] = parse(Int64, arr[1])
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

    function build_line_book(ob, level)::String
        depth_info = book_depth_info(ob, level)
        bid_stats = depth_info[:BID]
        bid_stats_vo = bid_stats[:volume]
        bid_stats_px = bid_stats[:price]
        ask_stats = depth_info[:ASK]
        ask_stats_vo = ask_stats[:volume]
        ask_stats_px = ask_stats[:price]
        actual = ""
        for cur in 1 : level
            if cur <= length(bid_stats_px)
                px = string(bid_stats_px[cur]) 
                if endswith(px, ".0")
                    px = replace(px, ".0"=> "")
                end
                if endswith(px, ".00")
                    px = replace(px, ".00"=> "")
                end
                actual *= px*"," *
                string(bid_stats_vo[cur]) * ","
            else
                actual *= ",,"
            end
            if cur <= length(ask_stats_px)
                
                px = string(ask_stats_px[cur])
                if endswith(px, ".0")
                    px = replace(px, ".0"=> "")
                end
                if endswith(px, ".00")
                    px = replace(px, ".00"=> "")
                end
                if cur < level
                    actual *= px *","*
                    string(ask_stats_vo[cur]) *","
                else
                    actual *= px *","*
                    string(ask_stats_vo[cur])
                end
            else
                if cur < level
                    actual *= ",,"
                else
                    actual *= ","
                end
            end
        end
        return actual;
    end

    function build_line_book2(ob, level)::String
        depth_info = book_depth_info(ob, level)
        bid_stats = depth_info[:BID]
        bid_stats_vo = bid_stats[:volume]
        bid_stats_px = bid_stats[:price]
        ask_stats = depth_info[:ASK]
        ask_stats_vo = ask_stats[:volume]
        ask_stats_px = ask_stats[:price]
        actual = []
        for cur in 1 : level
            if cur <= length(bid_stats_px)
                px = string(bid_stats_px[cur])
                if endswith(px, ".0")
                    px = replace(px, ".0"=> "")
                end
                if endswith(px, ".00")
                    px = replace(px, ".00"=> "")
                end
                push!(actual, px, ",", string(bid_stats_vo[cur]), ",")
            else
                push!(actual, ",,")
            end
            if cur <= length(ask_stats_px)
                px = string(ask_stats_px[cur])
                if endswith(px, ".0")
                    px = replace(px, ".0"=> "")
                end
                if endswith(px, ".00")
                    px = replace(px, ".00"=> "")
                end
                if cur < level
                    push!(actual, px, ",", string(ask_stats_vo[cur]), ",")
                else
                    push!(actual, px, ",", string(ask_stats_vo[cur]))
                end
            else
                if cur < level
                    push!(actual, ",,")
                else
                    push!(actual, ",")
                end
            end
        end
        return join(actual)
    end

    function finish_queued_message(dicts, ob, dict_time_price_from_actual_execution)
        while length(dicts) > 0
            dict = popfirst!(dicts)
            order_match_lst, shares_left = execute_with_displayed_message_first(ob, dict)
            dict_time_price_from_actual_execution[dict["timestamp"]] = order_match_lst[1].price
        end
    end

    function finish_queued_message_err(dicts, ob, dict_time_price_from_actual_execution_no_mod)
        while length(dicts) > 0
            dict = popfirst!(dicts)
            order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"])
            dict_time_price_from_actual_execution_no_mod[dict["timestamp"]] = order_match_lst[1].price
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

    function testing(s::Int, n::Int, level::Int, order_messages::String, order_book::String)
        
        order_book *= string(level)*".csv"
        io_order_messages = open("$(order_messages)", "r");
        io_order_book = open(order_book, "r");
        ob = MyLOBType()
        line_book = ""
        last_timestamp = ""
        last_price = 0f0
        dicts = Vector{Dict{String, Any}}()
        dict_time_price_from_message = Dict{Any, Any}() # only Type "A" and "E" can have this
        dict_time_price_from_actual_execution = Dict{Any, Any}() # only submit market order can have this
        
        for cur in 1 : n
            line_message = readline(io_order_messages)
            line_book = readline(io_order_book)
            
            if cur == 1 
                continue
            end
    
            dict = process_message_string(line_message)
    
            if dict["timestamp"] != last_timestamp || dict["order_type"] != "C"
                # some message come in queue at the same time but in different order types, we need to process the queued message first
                # some message come in same time but could be all executed at different prices, this might result in lower priority, 
                # We choose to queue them and execute as soon as we in the next timestamp.
                finish_queued_message(dicts, ob, dict_time_price_from_actual_execution)
            end
            if dict["order_type"] == "C" || dict["order_type"] == "E"
                dict_time_price_from_message[dict["timestamp"]] = dict["order_price"]
            end
    
            if dict["order_type"] == "A"
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
            elseif dict["order_type"] == "D"
                if dict["order_size"] == 0
                    # this applies all order canceled
                    cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
                else
                    # this will cancel partial orders but the priority remains the same
                    cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["cancel_size"])
                end
                
            elseif dict["order_type"] == "E"
                checked_id = check_market_order_priority_with_order_id!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
                
                if checked_id  == 1
                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], true)
                elseif dict["timestamp"] == last_timestamp &&  
                    dict["order_price"] == last_price && 
                    !isnothing(checked_id) && elevate_priority!(ob, checked_id, dict["order_side"], dict["order_price"])

                    # at the same time priority, we don't care so much about the order of execution, since it can happen at any priority
                    reduce_priorty_via_display_property!(ob, dict["order_id"], dict["order_side"], dict["order_price"], true)
                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], false)
                else
                    # at the different time priority, the order at lower priority executed first, this could be their display/non-display
                    # properties. The displayable order always have higher priority than non-dinplayable order

                    raise_priorty_via_display_property!(ob, dict["order_id"], dict["order_side"], dict["order_price"], false)
                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], false)
                end
                dict_time_price_from_actual_execution[dict["timestamp"]] = order_match_lst[1].price

            elseif dict["order_type"] == "R"
                cancel_order!(ob, dict["old_order_id"], dict["order_side"], dict["old_order_price"])
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"], )
            elseif dict["order_type"] == "P"
    
            elseif dict["order_type"] == "C"
                # aggressive pegging order is placed, it will have higher priority since the price is higher
                cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["old_order_price"], dict["execute_size"])
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["execute_size"], dict["mpid"], ALLOW_LOCKING)
                push!(dicts, dict)
            end
            last_timestamp = dict["timestamp"]
            if dict["order_type"] != "P"
                last_price = dict["order_price"]
            end
        end
        finish_queued_message(dicts, ob, dict_time_price_from_actual_execution)
    
        actual = build_line_book2(ob, level);
        close(io_order_messages)
        close(io_order_book)
        return actual, line_book, occursin(actual,line_book) , ob, dict_time_price_from_message, dict_time_price_from_actual_execution
    end

    function testing_no_mod(s::Int, n::Int, level::Int, order_messages::String, order_book::String)
        
        order_book *= string(level)*".csv"
        io_order_messages = open("$(order_messages)", "r");
        io_order_book = open(order_book, "r");
        ob = MyLOBType()
        line_book = ""
        last_timestamp = ""
        last_price = 0f0
        dicts = Vector{Dict{String, Any}}()
        dict_time_price_from_actual_execution_no_mod = Dict{Any, Any}() # only submit market order can have this
        
        for cur in 1 : n
            try
                line_message = readline(io_order_messages)
                line_book = readline(io_order_book)
                
                if cur == 1 
                    continue
                end
        
                dict = process_message_string(line_message)
                
                if dict["timestamp"] != last_timestamp || dict["order_type"] != "C"
                    finish_queued_message_err(dicts, ob, dict_time_price_from_actual_execution_no_mod)
                end


                if dict["order_type"] == "A"
                    submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
                elseif dict["order_type"] == "D"
                    if dict["order_size"] == 0
                        # this applies all order canceled
                        cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
                    else
                        # this will cancel partial orders but the priority remains the same
                        cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["cancel_size"])
                    end
                    
                elseif dict["order_type"] == "E"

                    order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"])
                    dict_time_price_from_actual_execution_no_mod[dict["timestamp"]] = order_match_lst[1].price

                elseif dict["order_type"] == "R"
                    cancel_order!(ob, dict["old_order_id"], dict["order_side"], dict["old_order_price"])
                    submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"], )
                elseif dict["order_type"] == "P"
        
                elseif dict["order_type"] == "C"
                    # aggressive pegging order is placed, it will have higher priority since the price is higher
                    cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["old_order_price"], dict["execute_size"])
                    submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["execute_size"], dict["mpid"], ALLOW_LOCKING)
                    push!(dicts, dict)
                end
            catch

            end
            
        end
        finish_queued_message_err(dicts, ob, dict_time_price_from_actual_execution_no_mod)
        actual = build_line_book2(ob, level);
        close(io_order_messages)
        close(io_order_book)
        return actual, line_book, occursin(actual,line_book) , ob, dict_time_price_from_actual_execution_no_mod
    end

    function plot_visualization(dict_time_price, ticker, file_name, suffix)
        time_vec = Vector{Any}()
        price_vec = Vector{Any}()
        for key in keys(dict_time_price)
            push!(time_vec, key)
        end
        time_vec = sort(time_vec)
        for key in time_vec
            push!(price_vec, dict_time_price[key])
        end
        x_array = time_vec[2 : end] ./ 3.6e+12
        y_array = price_vec[2 : end]
        scatter(x_array, y_array, label="Price", mc=:white, msc=colorant"#EF4035", legend=:best, ms = 0.5, markerstrokewidth = 0.5 ,
        bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
        xlabel!("Hours since midnight for ticker: $(ticker)", fontsize=18)
        ylabel!("Last Trading Price (USD)", fontsize=18)

        savefig("test/fig/$(file_name)/$(ticker)_$(suffix)_fig.pdf")

        write_io("test/fig/$(file_name)/$(ticker)_$(suffix)_x.txt", x_array)
        write_io("test/fig/$(file_name)/$(ticker)_$(suffix)_y.txt", y_array)
    end

    function plot_error(dict_mod, dict_no_mod, ticker, file_name)
        time_vec = Vector{Any}()
        price_vec = Vector{Any}()
        for key in keys(dict_no_mod)
            push!(time_vec, key)
        end
        time_vec = sort(time_vec)
        for key in time_vec
            push!(price_vec, dict_no_mod[key] - dict_mod[key])
        end
        x_array = time_vec[2 : end] ./ 3.6e+12
        y_array = price_vec[2 : end]
        scatter(x_array, y_array, label="Error", mc=:white, msc=colorant"#EF4035", legend=:best, ms = 0.5, markerstrokewidth = 0.5 ,
        bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
        xlabel!("Hours since midnight for ticker: $(ticker)", fontsize=18)
        ylabel!("Error", fontsize=18)

        savefig("test/fig/$(file_name)/$(ticker)_error_ploting_fig.pdf")

        write_io("test/fig/$(file_name)/$(ticker)_error_ploting_x.txt", x_array)
        write_io("test/fig/$(file_name)/$(ticker)_error_ploting_y.txt", y_array)
    end
end

function test_last_trade(file_name)
    Tickers = ["INTC", "AAPL", "MSFT", "SPY", "QQQ", "AMZN", "TSLA"]
    Volumes = [1601350, 2008467, 1854140, 4468109, 4754517, 670233, 1030765]

    mkdir("test/fig/$(file_name)")

    for i in eachindex(Tickers)
        @testset "test order book from actual ITCH50 data feed -> NDQ $(Tickers[i]) " begin
            order_messages = "data/messages/01302020.NASDAQ_ITCH50_$(Tickers[i])_message.csv"
            order_book = "data/book/01302020.NASDAQ_ITCH50_$(Tickers[i])_book_"
            _, _, flag, ob, dict_time_price_from_message, dict_time_price_from_actual_execution = testing(1, Volumes[i], 100, order_messages, order_book);
            # @test flag == true;
            # @test length(dict_time_price_from_message) == length(dict_time_price_from_actual_execution)
            # @test dict_time_price_from_message == dict_time_price_from_actual_execution
            plot_visualization(dict_time_price_from_actual_execution, Tickers[i], file_name, "act")
            _, _, flag, ob, dict_time_price_from_actual_execution_no_mod = testing_no_mod(1, Volumes[i], 100, order_messages, order_book);
            plot_visualization(dict_time_price_from_actual_execution_no_mod, Tickers[i], file_name, "err")
            plot_error(dict_time_price_from_actual_execution, dict_time_price_from_actual_execution_no_mod, Tickers[i], file_name);
        end
    end
end

test_last_trade("test_last_trade_price_with_err")

# include("test/validation/book_validation_visualization.jl")