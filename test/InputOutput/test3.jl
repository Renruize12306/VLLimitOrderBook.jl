using VL_LimitOrderBook


function process_file(io::IO, ob::OrderBook, file_name::String)
    io = open(file_name, "r");
    current_string = read(io, String)
    arr = split(current_string,"\n")
    for i = (1 + 1) : (length(arr) - 1)
        current_single_order = split(arr[i], ",")
        orderid = parse(Int64, current_single_order[2])
        side = current_single_order[3] == "OrderSide(Buy)" ? BUY_ORDER : SELL_ORDER
        price = parse(Float64, current_single_order[5])
        size = trunc(Int64, parse(Float64, current_single_order[4]))
        acct_id = parse(Int64, current_single_order[6])
        submit_limit_order!(ob,uob, orderid, side, price, size, acct_id)
    end
end


MyLOBType = OrderBook{Int64, Float32, Int64, Int64}
ob_test = MyLOBType()
file_name = "log.csv"
if (isfile(file_name))
    io = open(file_name, "r");
    process_file(io, ob_test)
end
