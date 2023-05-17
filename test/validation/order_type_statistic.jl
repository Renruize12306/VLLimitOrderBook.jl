using VLLimitOrderBook, Test

begin
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

    function testing(n::Int, order_messages::String)
        io_order_messages = open("$(order_messages)", "r");
        mapping = Dict{String, Int}()

        for cur in 1 : n
            line_message = readline(io_order_messages)
            
            if cur == 1 
                continue
            end


            dict = process_message_string(line_message)
            get!(mapping, dict["order_type"], 0)
            mapping[dict["order_type"]] += 1;
        end
        close(io_order_messages)
        ratio = Dict{Any, Any}()
        for (key, val) in mapping
            ratio[key] = val/n
        end
        println("========================================================================")
        println(order_messages, "\n\n", mapping)
        println("\n\n", ratio)
        println("\nMsg count, ", n, "\n")

        return mapping, n, ratio
    end
end

begin
    order_messages = "data/messages/01302020.NASDAQ_ITCH50_INTC_message.csv"
    dict, n, ratio = testing(1601350, order_messages);

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_AAPL_message.csv"
    dict, n, ratio = testing(2008467, order_messages);

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_MSFT_message.csv"
    dict, n, ratio = testing(1854140, order_messages);

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_SPY_message.csv"
    dict, n, ratio = testing(4468109, order_messages);

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_QQQ_message.csv"
    dict, n, ratio = testing(4754517, order_messages);

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_AMZN_message.csv"
    dict, n, ratio = testing(670233, order_messages);

    order_messages = "data/messages/01302020.NASDAQ_ITCH50_TSLA_message.csv"
    dict, n, ratio = testing(1030765, order_messages);
end

# include("test/validation/order_type_statistic.jl")