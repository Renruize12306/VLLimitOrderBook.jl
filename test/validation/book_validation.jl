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

end

# @testset "test order book from actual ITCH50 data feed -> submit and cancel 1" begin
#     order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
#     # order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_36.csv"
#     io_order_messages = open(order_messages, "r");
#     # io_order_book = open(order_book, "r");
#     ob = MyLOBType()
#     for cur in 1 : 13
#         line_message = readline(io_order_messages)
#         # line_book = readline(io_order_book)
#         if cur == 1 
#             continue
#         end
#         dict = process_message_string(line_message)
#         if dict["order_type"] == "A"
#             submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
#         elseif  dict["order_type"] == "D"
#             cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
#         end
#     end
#     close(io_order_messages)
#     @test (isempty(ob.bid_orders) && isempty(ob.ask_orders))  == true
    
# end

# @testset "test order book from actual ITCH50 data feed -> submit and cancel 2" begin
#     order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
#     # order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_36.csv"
#     io_order_messages = open(order_messages, "r");
#     # io_order_book = open(order_book, "r");
#     ob = MyLOBType()
#     for cur in 1 : 17
#         line_message = readline(io_order_messages)
#         # line_book = readline(io_order_book)
#         if cur == 1 
#             continue
#         end
#         dict = process_message_string(line_message)
#         if dict["order_type"] == "A"
#             submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
#         elseif  dict["order_type"] == "D"
#             cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
#         end
#     end
#     close(io_order_messages)
#     @test (isempty(ob.bid_orders) && isempty(ob.ask_orders))  == true
# end

# @testset "test order book from actual ITCH50 data feed -> submit, cancel n execute" begin
#     order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
#     # order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_36.csv"
#     io_order_messages = open(order_messages, "r");
#     # io_order_book = open(order_book, "r");
#     ob = MyLOBType()
#     for cur in 1 : 266
#         line_message = readline(io_order_messages)
#         # line_book = readline(io_order_book)
#         if cur == 1 
#             continue
#         end
#         # println(line_message)
#         dict = process_message_string(line_message)
#         if dict["order_type"] == "A"
#             submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"])
#         elseif dict["order_type"] == "D"
#             cancel_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"])
#         elseif dict["order_type"] == "E"
#             before_matching = ob.ask_orders.total_volume
#             order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"])
#             @test shares_left == 0
#             @test length(order_match_lst) == 1
#             after_matching = ob.ask_orders.total_volume
#             @test order_match_lst[1].size == before_matching - after_matching
#         end
#     end
#     close(io_order_messages)
# end

# @testset "test order book from actual ITCH50 data feed -> submit, cancel n execute" begin

# end
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
function testing(n::Int, level::Int, order_messages::String, order_book::String)
    
    order_book *= string(level)*".csv"
    io_order_messages = open(order_messages, "r");
    io_order_book = open(order_book, "r");
    ob = MyLOBType()
    line_book = ""
    for cur in 1 : n
        line_message = readline(io_order_messages)
        line_book = readline(io_order_book)
        
        if cur == 1 
            continue
        end
        # println(line_message)
        if cur == 22588
            println()
        end
        dict = process_message_string(line_message)
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
        elseif dict["order_type"] == "R"
            cancel_order!(ob, dict["old_order_id"], dict["order_side"], dict["old_order_price"])
            submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["order_size"], dict["mpid"], )
        elseif dict["order_type"] == "P"

        elseif dict["order_type"] == "C"
            # aggressive pegging order is placed, it will have higher priority since the price is higher
            cancel_partial_order!(ob, dict["order_id"], dict["order_side"], dict["old_order_price"], dict["execute_size"])
            submit_limit_order!(ob, dict["order_id"], dict["order_side"], dict["order_price"], dict["execute_size"], dict["mpid"], ALLOW_LOCKING)
            order_match_lst, shares_left = submit_market_order!(ob, dict["order_side"], dict["execute_size"])
        end
        # begin # testing each line
        #     actual = build_line_book2(ob, level);
        #     mark = occursin(actual,line_book)
        #     println("Round: ", cur, "\tFlag: ", mark)
        #     if (!mark)
        #         break;
        #     end
        # end
    end
    actual = build_line_book2(ob, level);
    close(io_order_messages)
    close(io_order_book)
    return actual, line_book, occursin(actual,line_book) , ob
end

# # PSX MSFT 
# order_messages = "data/messages/03272019.PSX_ITCH50_MSFT_message.csv"
# order_book = "data/book/03272019.PSX_ITCH50_MSFT_book_"
# _, _, flag, ob = testing(503954, 36, order_messages, order_book)



# # INTC NDQ all passed
# order_messages = "data/messages/01302020.NASDAQ_ITCH50_INTC_message.csv"
# order_book = "data/book/01302020.NASDAQ_ITCH50_INTC_book_"
# _, _, flag, ob = testing(1601350, 100, order_messages, order_book)
# # @time _, _, flag, ob = testing(10350, 100, order_messages, order_book)


# # AAPL NDQ
# order_messages = "data/messages/01302020.NASDAQ_ITCH50_AAPL_message.csv"
# order_book = "data/book/01302020.NASDAQ_ITCH50_AAPL_book_"
# # @time _, _, flag, ob = testing(2008468, 100, order_messages, order_book)
# @time _, _, flag, ob = testing(19527, 100, order_messages, order_book)


# # MSFT NDQ
# order_messages = "data/messages/01302020.NASDAQ_ITCH50_MSFT_message.csv"
# order_book = "data/book/01302020.NASDAQ_ITCH50_MSFT_book_"
# # @time _, _, flag, ob = testing(1854140, 100, order_messages, order_book)
# @time _, _, flag, ob = testing(22588, 100, order_messages, order_book)
_, _, flag, ob = testing(22480, 100, order_messages, order_book)

# SPY NDQ
order_messages = "data/messages/01302020.NASDAQ_ITCH50_SPY_message.csv"
order_book = "data/book/01302020.NASDAQ_ITCH50_SPY_book_"
# @time _, _, flag, ob = testing(1854140, 100, order_messages, order_book)
@time _, _, flag, ob = testing(4468109, 100, order_messages, order_book)