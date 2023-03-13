using VLLimitOrderBook, Test

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

    function testing(s::Int, n::Int, level::Int, order_messages::String, order_book::String)
        
        order_book *= string(level)*".csv"
        io_order_messages = open("$(order_messages)", "r");
        io_order_book = open(order_book, "r");
        ob = MyLOBType()
        line_book = ""
        last_timestamp = ""
        last_price = 0f0
        dicts = Vector{Dict{String, Any}}()
    
        for cur in 1 : n
            line_message = readline(io_order_messages)
            line_book = readline(io_order_book)
            
            if cur == 1 
                continue
            end
    
            # if cur == 1818157
            #     println()
            # end
    
            dict = process_message_string(line_message)
    
            if dict["timestamp"] != last_timestamp || dict["order_type"] != "C"
                # some message come in queue at the same time but in different order types, we need to process the queued message first
                # some message come in same time but could be all executed at different prices, this might result in lower priority, 
                # We choose to queue them and execute as soon as we in the next timestamp.
                finish_queued_message(dicts, ob)
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
    
                # if checked_id  == 1
                #     order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], true)
                # else
                #     raise_priorty_via_display_property!(ob, dict["order_id"], dict["order_side"], dict["order_price"], false)
                #     order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"], false)
                # end

            elseif dict["order_type"] == "R"
                cancel_order!(ob, dict["old_order_id"], dict["order_side"], dict["old_order_price"])
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"], )
            elseif dict["order_type"] == "P"
    
            elseif dict["order_type"] == "C"
                # aggressive pegging order is placed, it will have higher priority since the price is higher
                cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["old_order_price"], dict["execute_size"])
                submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["execute_size"], dict["mpid"], ALLOW_LOCKING)
                # order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"])
                push!(dicts, dict)
            end
            last_timestamp = dict["timestamp"]
            if dict["order_type"] != "P"
                last_price = dict["order_price"]
            end
            # begin # This part examine every line of the messages
            #     if cur >= s
            #         if dict["order_type"] != "C"
            #             actual = build_line_book2(ob, level);
            #             mark = occursin(actual,line_book)
            #             println(order_book, "\tRound: ", cur, "\tFlag: ", mark)
            #             if (!mark)
            #                 break;
            #             end
            #         else 
            #             println(cur, " is in unchecked_index set")
            #         end
            #     end
            # end
        end
        finish_queued_message(dicts, ob)
    
        actual = build_line_book2(ob, level);
        close(io_order_messages)
        close(io_order_book)
        return actual, line_book, occursin(actual,line_book) , ob
    end
end

@testset "test order book from actual ITCH50 data feed -> submit and cancel 1" begin
    order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
    # order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_36.csv"
    io_order_messages = open(order_messages, "r");
    # io_order_book = open(order_book, "r");
    ob = MyLOBType()
    for cur in 1 : 13
        line_message = readline(io_order_messages)
        # line_book = readline(io_order_book)
        if cur == 1 
            continue
        end
        dict = process_message_string(line_message)
        if dict["order_type"] == "A"
            submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
        elseif  dict["order_type"] == "D"
            cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
        end
    end
    close(io_order_messages)
    @test (isempty(ob.bid_orders) && isempty(ob.ask_orders))  == true
    
end

@testset "test order book from actual ITCH50 data feed -> submit and cancel 2" begin
    order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
    # order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_36.csv"
    io_order_messages = open(order_messages, "r");
    # io_order_book = open(order_book, "r");
    ob = MyLOBType()
    for cur in 1 : 17
        line_message = readline(io_order_messages)
        # line_book = readline(io_order_book)
        if cur == 1 
            continue
        end
        dict = process_message_string(line_message)
        if dict["order_type"] == "A"
            submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
        elseif  dict["order_type"] == "D"
            cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
        end
    end
    close(io_order_messages)
    @test (isempty(ob.bid_orders) && isempty(ob.ask_orders))  == true
end

@testset "test order book from actual ITCH50 data feed -> submit, cancel n execute" begin
    order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
    # order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_36.csv"
    io_order_messages = open(order_messages, "r");
    # io_order_book = open(order_book, "r");
    ob = MyLOBType()
    for cur in 1 : 266
        line_message = readline(io_order_messages)
        # line_book = readline(io_order_book)
        if cur == 1 
            continue
        end
        # println(line_message)
        dict = process_message_string(line_message)
        if dict["order_type"] == "A"
            submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
        elseif dict["order_type"] == "D"
            cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
        elseif dict["order_type"] == "E"
            before_matching = ob.ask_orders.total_volume
            order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"])
            @test shares_left == 0
            @test length(order_match_lst) == 1
            after_matching = ob.ask_orders.total_volume
            @test order_match_lst[1].size == before_matching - after_matching
        end
    end
    close(io_order_messages)
end

@testset "test order book from actual ITCH50 data feed -> PSX MSFT " begin
    order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
    order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_"
    # uncheck_index = Set()
    # _, _, flag, ob = testing(164643, 168827, 36, order_messages, order_book, uncheck_index)
    _, _, flag, ob = testing(1, 503954, 36, order_messages, order_book);
    @test flag == true;
end

@testset "test order book from actual ITCH50 data feed -> NDQ INTC " begin
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_INTC_message.csv"
    order_book = "data/book/01302020.NASDAQ_ITCH50_INTC_book_"
    # uncheck_index = Set()
    _, _, flag, ob = testing(1, 1601350, 100, order_messages, order_book);
    @test flag == true;
end

@testset "test order book from actual ITCH50 data feed -> NDQ AAPL " begin
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_AAPL_message.csv"
    order_book = "data/book/01302020.NASDAQ_ITCH50_AAPL_book_"
    # @time _, _, flag, ob = testing(2008468, 100, order_messages, order_book)
    # uncheck_index = Set()
    @time _, _, flag, ob = testing(1, 2008467, 100, order_messages, order_book);
    @test flag == true;
end

@testset "test order book from actual ITCH50 data feed -> NDQ MSFT " begin
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_MSFT_message.csv"
    order_book = "data/book/01302020.NASDAQ_ITCH50_MSFT_book_"
    # uncheck_index = Set([27708,1818157, 1818158, 1818159, 1818160])
    @time _, _, flag, ob = testing(1, 1854140, 100, order_messages, order_book);
    @test flag == true;
end

@testset "test order book from actual ITCH50 data feed -> NDQ SPY " begin
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_SPY_message.csv"
    order_book = "data/book/01302020.NASDAQ_ITCH50_SPY_book_"
    # uncheck_index = Set()
    @time _, _, flag, ob = testing(1, 4468109, 100, order_messages, order_book);
    @test flag == true;
end

@testset "test order book from actual ITCH50 data feed -> NDQ QQQ " begin
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_QQQ_message.csv"
    order_book = "data/book/01302020.NASDAQ_ITCH50_QQQ_book_"
    # uncheck_index = Set()
    @time _, _, flag, ob = testing(1, 4754517, 100, order_messages, order_book);
    @test flag == true;
end

# # AMZN
# order_messages = "data/messages/01302020.NASDAQ_ITCH50_AMZN_message.csv"
# order_book = "data/book/01302020.NASDAQ_ITCH50_AMZN_book_"

# # TSLA
# order_messages = "data/messages/01302020.NASDAQ_ITCH50_TSLA_message.csv"
# order_book = "data/book/01302020.NASDAQ_ITCH50_TSLA_book_"
