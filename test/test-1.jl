using AVLTrees
using Base.Iterators: zip,cycle,take,filter, flatten
using Dates
begin # Create (Deterministic) Limit Order Generator
    MyOrderSubTypes = (Int64,Float32,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
    MyOrderType = Order{MyOrderSubTypes...}
    MyLOBType = OrderBook{MyOrderSubTypes...}
    orderid_iter = Base.Iterators.countfrom(1)
    sign_iter = cycle([1,-1,-1,1,1,-1])
    side_iter = ( s>0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
    spread_iter = cycle([3 2 3 2 2 2 3 2 3 4 2 2 3 2 3 2 3 3 2 2 3 2 5 2 2 2 2 2 4 2 3 6 5 6 3 2 3 5 4]*1e-2)
    price_iter = ( Float32(100.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
    size_iter = cycle([2,5,3,4,10,15,1,6,13,11,4,1,5])
    # zip them all together
    lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)
end

begin # Create (Deterministic) Market Order Generator
    mkt_size_iter = cycle([10,20,30,15,25,5,7])
    mkt_side_iter = cycle([SELL_ORDER,BUY_ORDER,BUY_ORDER,SELL_ORDER,BUY_ORDER,SELL_ORDER])
    mkt_order_info_iter = zip(mkt_size_iter,mkt_side_iter)
end

@testset "Submit and Cancel 1" begin # Add and delete all orders, verify book is empty, verify account tracking
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,50000)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    @test length(ob.acct_map[10101]) == 50000 # Check account order tracking
    first_order = collect(take(lmt_order_info_iter,1))[1]
    poped_expected_nothing = cancel_order!(ob, first_order[1]+1, first_order[4],first_order[2])
    @test isnothing(poped_expected_nothing)
    # Cancel them all
    for (orderid, price, size, side) in order_info_lst
        cancel_order!(ob,orderid,side,price)
    end
    # Check emptiness
    @test isempty(ob.bid_orders)
    @test isempty(ob.ask_orders)
    @test isempty(ob.acct_map[10101])
end
@testset "Test submit limit orders handling errors and edge cases" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    @test_throws ErrorException("The orderbook should not be crossed, the bid limit order should not exceed the minimum ASK price") submit_limit_order!(ob, 10086, BUY_ORDER, 110,10101)
    @test_throws ErrorException("The orderbook should not be crossed, the ask limit order should not exceed the maximus BID price") submit_limit_order!(ob, 10086, SELL_ORDER, 99,10101)
    @test_throws ErrorException("Both limit_price and limit_size must be positive") submit_limit_order!(ob, 10086, BUY_ORDER, -110,10101)
    @test_throws ErrorException("Both limit_price and limit_size must be positive") submit_limit_order!(ob, 10086, BUY_ORDER, 110,-10101)
    new_open_order, cross_match_lst, remaining_size = submit_limit_order!(ob, 10086, SELL_ORDER, 100,10,10101,IMMEDIATEORCANCEL_FILLTYPE)
    @test isnothing(new_open_order)
    @test length(cross_match_lst) == 0
    @test remaining_size == 10
end
@testset "Test cancel empty orders" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    @test length(ob.acct_map[10101]) == 6 # Check account order tracking
    fourth_order = collect(take(lmt_order_info_iter,4))[4]
    touple = (fourth_order[1], fourth_order[4], 100.05)
    poped_expected_nothing = cancel_order!(ob, touple...)
    @test isnothing(poped_expected_nothing)
    touple = (fourth_order[1]+123234, fourth_order[4], fourth_order[2])
    poped_expected_nothing = cancel_order!(ob, touple...)
    @test isnothing(poped_expected_nothing)
end
# Market order side should be discussed
# Limit order to match market order or just submit all to the brokers
@testset "MO Liquidity Wipe" begin # Wipe out book completely, try MOs on empty book
    ob = MyLOBType() #Initialize empty book
    # Add a bunch of orders
    for (orderid, price, size, side) in Base.Iterators.take( lmt_order_info_iter, 50 )
        submit_limit_order!(ob,orderid,BUY_ORDER,price,size,10101)
    end
    mo_matches, mo_ltt = submit_market_order!(ob,BUY_ORDER,100000)

    # Tests
    @test length( mo_matches ) == 50
    @test mo_ltt > 0
    @test isempty(submit_market_order!(ob,BUY_ORDER,10000)[1] )
    @test isempty(ob.bid_orders)
    @test isempty(ob.ask_orders)
end

@testset "MO Liquidity Wipe With Non-Display Order setup" begin # Wipe out book completely, try MOs on empty book
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,20)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    queues = VLLimitOrderBook._get_price_queue(ob.ask_orders, Float32(100.02))
    order_modified = raise_priorty_via_display_property!(ob, 11, SELL_ORDER, Float32(100.02), false)
    order_match_lst, shares_left = submit_market_order!(ob, SELL_ORDER, 2, false)
    @test length(order_match_lst) == 1
    @test order_match_lst[1].size == 2
    @test shares_left == 0
end
@testset "Test Submit Market Order edge cases" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    order_match_lst, shares_left = submit_market_order!(ob,BUY_ORDER,24,false,ALLORNONE_FILLTYPE)
    @test length(order_match_lst) == 0
    @test shares_left == 24
end
@testset "Order match exact - bid" begin # Test correctness in order matching system / Stat calculation (:BID)
    ob = MyLOBType() #Initialize empty book
    # record order book info before
    order_lst_tmp = Base.Iterators.take( Base.Iterators.filter( x-> x[4]===BUY_ORDER, lmt_order_info_iter), 7 ) |> collect

    # Add a bunch of orders
    for (orderid, price, size, side) in order_lst_tmp
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end

    orders_before = Iterators.flatten(q.queue for (k,q) in ob.bid_orders.book) |> collect

    # record information from before
    expected_bid_volm_before = sum( x[3] for x in order_lst_tmp )
    expected_bid_n_orders_before =  length(order_lst_tmp)


    # execute MO
    mo_matches, mo_ltt = submit_market_order!(ob,BUY_ORDER,30)
    mo_match_sizes = [o.size for o in mo_matches]

    # record what is expected to be seen
    expected_bid_volm_after = expected_bid_volm_before - 30
    expected_bid_n_orders_after = expected_bid_n_orders_before - 5
    expected_best_bid_after = Float32(99.97)

    # record what is expected of MO result
    expected_mo_match_size = [5,15,6,1,2,1]

    # Compute realized values
    book_info_after = book_depth_info(ob,1000)
    realized_bid_volm_after  = sum(book_info_after[:BID][:volume])
    realized_bid_n_orders_after = sum(book_info_after[:BID][:orders])
    realized_best_bid_after = first(book_info_after[:BID][:price])

    # Check all expected vs realized values
    @test realized_bid_volm_after == expected_bid_volm_after
    @test realized_bid_n_orders_after == expected_bid_n_orders_after
    @test realized_best_bid_after == expected_best_bid_after
    @test mo_match_sizes == expected_mo_match_size
    @test mo_ltt == 0
end
@testset "Test Base Order Check and Print Function" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    bid_order_queue_100_02 = AVLTrees.findkey(ob.ask_orders.book, Float32(100.02))
    @test length(bid_order_queue_100_02) == 2
    file_name = "base_show_orderqueue.txt"
    io = open(file_name, "w");
    Base.print(io, bid_order_queue_100_02)
    poped_order_1 = Base.popfirst!(bid_order_queue_100_02)
    poped_order_2 = Base.popfirst!(bid_order_queue_100_02)
    poped_order_3 = Base.popfirst!(bid_order_queue_100_02)
    
    @test isnothing(poped_order_3)
    Base.print(io, poped_order_1)
    Base.show(io, poped_order_1)
    close(io)
    expected_output = "OrderQueue at price=$(bid_order_queue_100_02.price):\n"*
        " Order{Int64,Float32,Int64,Int64}( side=OrderSide(Sell), size=4, price=100.02, orderid=4, acctid=10101, fill_mode=OrderTraits(allornone=false, immediateorcancel=false, allowlocking=false), display=true )\n"*
        " Order{Int64,Float32,Int64,Int64}( side=OrderSide(Sell), size=10, price=100.02, orderid=5, acctid=10101, fill_mode=OrderTraits(allornone=false, immediateorcancel=false, allowlocking=false), display=true )\n"*
        "Order{Int64,Float32,Int64,Int64}( side=OrderSide(Sell), size=4, price=100.02, orderid=4, acctid=10101, fill_mode=OrderTraits(allornone=false, immediateorcancel=false, allowlocking=false), display=true )\n"*
        "Order{Int64,Float32,Int64,Int64}( side=OrderSide(Sell), size=4, price=100.02, orderid=4, acctid=10101, fill_mode=OrderTraits(allornone=false, immediateorcancel=false, allowlocking=false), display=true )\n"
    output_contents = read("base_show_orderqueue.txt", String)
    @test output_contents == expected_output
end
@testset "Test Base Order Check and Print Function" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    bid_order_queue_100_02 = AVLTrees.findkey(ob.ask_orders.book, Float32(100.02))
    @test length(bid_order_queue_100_02) == 2
    poped_order_1 = Base.popfirst!(bid_order_queue_100_02)
    file_name = "base_show_order_property.txt"
    io = open(file_name, "w");
    Base.show(io, poped_order_1.side)
    Base.println(io)
    Base.show(io, "text/plain", poped_order_1.side)
    Base.println(io)
    Base.show(io, "text/plain", VANILLA_FILLTYPE)
    Base.println(io)
    Base.print(io, VANILLA_FILLTYPE)
    close(io)
    expected_output = "OrderSide(Sell)\n"*
            "OrderSide(Sell)\n"*
            "OrderTraits(allornone=$(VANILLA_FILLTYPE.allornone), immediateorcancel=$(VANILLA_FILLTYPE.immediateorcancel), allowlocking=$(VANILLA_FILLTYPE.allowlocking))\n"*
            "OrderTraits(allornone=$(VANILLA_FILLTYPE.allornone), immediateorcancel=$(VANILLA_FILLTYPE.immediateorcancel), allowlocking=$(VANILLA_FILLTYPE.allowlocking))"
    output_contents = read("base_show_order_property.txt", String)
    @test output_contents == expected_output
    
end
# Market order side should be discussed
@testset "Test MO, LO insert, LO cancel outputs" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,500)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end

    # Test that inserting LO returns correctly
    lmt_info = (10_000, BUY_ORDER, 99.97f0, 3, 10101)
    lmt_obj, _, _ = submit_limit_order!(ob,lmt_info...)
    @test lmt_info[1:4] == (lmt_obj.orderid,lmt_obj.side,lmt_obj.price,lmt_obj.size)
  
    # Test that cancelling present order returns correctly
    lmt_obj_cancel = cancel_order!(ob,lmt_obj)
    @test lmt_obj_cancel == lmt_obj

    # Test that missing order returns correctly
    lmt_obj_cancel_2 = cancel_order!(ob,lmt_obj_cancel)
    @test isnothing(lmt_obj_cancel_2)

    # Test that complete MO returns correctly
    mo_match_list, mo_ltt = submit_market_order!(ob,BUY_ORDER,100)
    @test typeof(mo_match_list) <: Vector{<:Order}
    @test mo_ltt == 0

    mo_match_list, mo_ltt = submit_market_order!(ob,SELL_ORDER,797+13)
    @test length(mo_match_list) == 137
    @test mo_ltt == 0

    mo_match_list, mo_ltt = submit_market_order!(ob,SELL_ORDER,13)
    @test !isempty(mo_match_list)
    @test mo_ltt == 0
    @test 13 == sum(x.size for x in mo_match_list)


end

@testset "Test Function Sumbit Market Order By funds nornal case" begin
    MyOrderSubTypes1 = (Float32,Float32,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
    MyOrderType1 = Order{MyOrderSubTypes...}
    MyLOBType1 = OrderBook{MyOrderSubTypes...}
    ob = MyLOBType1() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    order_match_list, fund_left = submit_market_order_byfunds!(ob, SELL_ORDER, 99.98)
    @test length(order_match_list) == 1
    @test fund_left == 0
    order_match_list, fund_left = submit_market_order_byfunds!(ob, SELL_ORDER, 200)
    @test sum(x.size for x in order_match_list) == 2
    @test abs(fund_left-0.04f0) <= 0.0
    order_match_list, fund_left = submit_market_order_byfunds!(ob, SELL_ORDER, 2000)
    @test sum(x.size for x in order_match_list) == 20
    @test abs(fund_left-0.43f0) <= 0.0
    order_match_list, fund_left = submit_market_order_byfunds!(ob, BUY_ORDER, 200)
    @test sum(x.size for x in order_match_list) == 1
    @test abs(fund_left-99.98f0) <= 0.0
    order_match_list, fund_left = submit_market_order_byfunds!(ob, BUY_ORDER, 401)
    @test sum(x.size for x in order_match_list) == 4
    @test abs(fund_left-0.92f0) <= 0.0
    order_match_list, fund_left = submit_market_order_byfunds!(ob, BUY_ORDER, 100)
    @test length(order_match_list) == 0
    @test abs(fund_left-100f0) <= 0.0
end

@testset "Test Function Sumbit Market Order By funds edge case_float quantity" begin
    MyOrderSubTypes1 = (Float32,Float32,Int64,Int64) # define types for Order Size, Price, Order IDs, Account IDs
    MyOrderType1 = Order{MyOrderSubTypes1...}
    MyLOBType1 = OrderBook{MyOrderSubTypes1...}
    ob = MyLOBType1() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    order_match_list, fund_left = submit_market_order_byfunds!(ob, BUY_ORDER, 50)
    @test sum(x.size for x in order_match_list) == 0.49990004f0
end

@testset "Test Function Sumbit Market Order By funds edge ALLORNONE_FILLTYPE" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    order_match_list, fund_left = submit_market_order_byfunds!(ob, SELL_ORDER, 100000, ALLORNONE_FILLTYPE)
    @test length(order_match_list) == 0
    @test fund_left-100000 <= 0.0
end


@testset "Test Account Tracking" begin
    ob = MyLOBType() #Initialize empty book

    # Add a bunch of orders
    for (orderid, price, size, side) in take(lmt_order_info_iter,100)
        submit_limit_order!(ob,orderid,side,price,size)
    end
    
    # Add order with an account ID
    acct_id = 1313
    order_id0 = 10001
    my_acct_orders = MyOrderType[]
    push!(my_acct_orders,submit_limit_order!(ob,order_id0,SELL_ORDER,100.03f0,50,acct_id)[1])
    push!(my_acct_orders,submit_limit_order!(ob,order_id0+1,BUY_ORDER,99.98f0,20,acct_id)[1])
    push!(my_acct_orders,submit_limit_order!(ob,order_id0+2,BUY_ORDER,99.97f0,30,acct_id)[1])

    # Throw some more nameless orders on top
    for (orderid, price, size, side) in take(lmt_order_info_iter,20)
        submit_limit_order!(ob,orderid,side,price,size)
    end

    # Get account list from book
    book_acct_list = collect(get_acct(ob,acct_id))
    @test (order_id0 .+ collect(0:2)) == [first(x) for x in book_acct_list] # Test correct ids
    @test my_acct_orders == [last(x) for x in book_acct_list] # Test correct orders
    @test isnothing(get_acct(ob,0))

    # Delete some orders and maintain checks
    to_canc = popat!(my_acct_orders,2)
    canc_order = cancel_order!(ob,to_canc)
    @test to_canc == canc_order
    book_acct_list = collect(get_acct(ob,acct_id))
    @test to_canc ∉ book_acct_list

end

@testset "Test Bid/Ask Volume & Number of Orders Checking" begin
    ob = MyLOBType() #Initialize empty book
    order_lst_tmp = Base.Iterators.take( lmt_order_info_iter, 10 ) |> collect

    # Add a bunch of orders
    for (orderid, price, size, side) in order_lst_tmp
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    actual_vol = volume_bid_ask(ob)
    expected_bid_vol = 42
    expected_ask_vol = 28
    @test (expected_bid_vol, expected_ask_vol) == actual_vol

    actual_num = n_orders_bid_ask(ob)
    expected_bid_num = 5
    expected_ask_num = 5
    @test (expected_bid_num, expected_ask_num) == actual_num
end

@testset "Test Order Types Checking" begin
    ob = MyLOBType() #Initialize empty book
    expected_types = (Int64, Float32, Int64, Int64)
    @test order_types(ob) == expected_types
    @test order_types(ob.bid_orders) == expected_types
    @test order_types(ob.ask_orders) == expected_types
    @test order_types(ob.ask_orders) == expected_types
    # Add an order
    lmt_info = (10_000, BUY_ORDER, 99.97f0, 3, 10101)
    lmt_obj, _, _ = submit_limit_order!(ob,lmt_info...)
    @test order_types(lmt_obj) == expected_types
end

@testset "Test Bid/Ask Order Iterators" begin
    ob = MyLOBType() #Initialize empty book
    order_lst_tmp = Base.Iterators.take( lmt_order_info_iter, 10 ) |> collect

    # Add a bunch of orders
    bid_submitted_orders = MyOrderType[]
    ask_submitted_orders = MyOrderType[]
    for (orderid, price, size, side) in order_lst_tmp
        lmt_obj, _, _ = submit_limit_order!(ob,orderid,side,price,size,10101)
        if (side == SELL_ORDER)
            push!(ask_submitted_orders, lmt_obj)
        else 
            push!(bid_submitted_orders, lmt_obj)
        end
    end
    for (i, item) in enumerate(ask_orders(ob))
        @test item ∈ ask_submitted_orders
    end
    for (i, item) in enumerate(bid_orders(ob))
        @test item ∈ bid_submitted_orders
    end
end

@testset "Test Write & Read with CSV file" begin
    ob = MyLOBType()
    order_info_lst = take(lmt_order_info_iter,6)
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end

    file_name = "log_ob.csv"
    io_original = open(file_name, "w");
    write_to_csv(io_original,ob)

    ob_test = MyLOBType()
    if (isfile(file_name))
        io_read = open(file_name, "r");
        read_from_csv(io_read, ob_test, file_name)
    end
    close(io_read)
    file_name = "log_ob_test.csv"
    io_test = open(file_name, "w");
    write_to_csv(io_test,ob_test)
    # compare those two CSV files
    contents1 = readlines(io_original)
    contents2 = readlines(io_test)
    close(io_original)
    close(io_test)
    #
    @test contents1 == contents2
    
end

@testset "Test clear_book Function" begin
    ob = MyLOBType()
    order_info_lst = take(lmt_order_info_iter,10)
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    cleared_bids, cleared_asks = clear_book!(ob, 3)
    @test length(cleared_bids) == 0
    @test length(cleared_asks) == 0
    cleared_bids, cleared_asks = clear_book!(ob, 2)
    @test length(cleared_bids) == 0
    @test length(cleared_asks) == 1
    cleared_bids, cleared_asks = clear_book!(ob, 1)
    @test length(cleared_bids) == 2
    @test length(cleared_asks) == 2
end

@testset "Test Base Show Function" begin
    ob = MyLOBType()
    file_name = "base_show.txt"
    io = open(file_name, "w");
    Base.show(io,"text/plain", ob)
    order_info_lst = take(lmt_order_info_iter,2)
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    Base.show(io, ob)
    Base.show(io,"text/plain", ob)
    close(io)
    expected_output = "OrderBook{Sz=Int64,Px=Float32,Oid=Int64,Aid=Int64} with properties:\n"*
    "  ⋄ best bid/ask price: (nothing, nothing)\n"*
    "  ⋄ total bid/ask volume: (0, 0)\n"*
    "  ⋄ total bid/ask orders: (0, 0)\n"*
    "  ⋄ flags = [:PlotTickMax => 5]\n"*
    "\n Order Book histogram (within 5 ticks of center):\n"*
    "\n\n    :BID   <empty>\n"*
    "\n    :ASK   <empty>\n"*
    "OrderBook{Sz=Int64,Px=Float32,Oid=Int64,Aid=Int64} with properties:\n"*
    "  ⋄ best bid/ask price: $(best_bid_ask(ob))\n"*
    "  ⋄ total bid/ask volume: $(volume_bid_ask(ob))\n"*
    "  ⋄ total bid/ask orders: $(n_orders_bid_ask(ob))\n"*
    "  ⋄ flags = $([ k => v for (k,v) in ob.flags])\n"*
    "OrderBook{Sz=Int64,Px=Float32,Oid=Int64,Aid=Int64} with properties:\n"*
    "  ⋄ best bid/ask price: $(best_bid_ask(ob))\n"*
    "  ⋄ total bid/ask volume: $(volume_bid_ask(ob))\n"*
    "  ⋄ total bid/ask orders: $(n_orders_bid_ask(ob))\n"*
    "  ⋄ flags = $([ k => v for (k,v) in ob.flags])\n"*
    "\n Order Book histogram (within 5 ticks of center):\n"*
    "\n                                                       "*
    "\n   :BID 99.98 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 5  \n"*
    "                                                       \n"*
    "\n                                                        \n"*
    "   :ASK 100.03 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 2  \n"*
    "                                                        \n"
    output_contents = read("base_show.txt", String)
    @test output_contents == expected_output
end

@testset "Test order traits" begin
    @test VLLimitOrderBook.isfillorkill(VANILLA_FILLTYPE) == false
    @test VLLimitOrderBook.allows_partial_fill(VANILLA_FILLTYPE) == true
end

@testset "Test Ordermatching.jl -> cancel_partial_order!" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    
    poped_size = cancel_partial_order!(ob, 4, SELL_ORDER, 100.02, 1)
    @test poped_size == 1
    
    poped_size = cancel_partial_order!(ob, 2, BUY_ORDER, 99.98, 2)
    
    @test poped_size == 2
    
    poped_size = cancel_partial_order!(ob, 2, BUY_ORDER, 99.98, 3)
    
    @test poped_size == 3
    
    poped_size = cancel_partial_order!(ob, 3, BUY_ORDER, 99.97, 3)
    
    @test poped_size == 3

    poped_size = cancel_partial_order!(ob, 3, BUY_ORDER, 99.9, 3)
    @test isnothing(poped_size)
end

@testset "Test Ordermatching.jl -> check_order_with_id_and_price!" begin
    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,6)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end

    priority = check_market_order_priority_with_order_id!(ob, 6, BUY_ORDER, 99.98)
    @test priority == 2

    priority = check_market_order_priority_with_order_id!(ob, 2, BUY_ORDER, 99.98)
    @test priority == 1

    priority = check_market_order_priority_with_order_id!(ob, 4, BUY_ORDER, 99.98)
    @test isnothing(priority)

    priority = check_market_order_priority_with_order_id!(ob, 4, BUY_ORDER, 99.00)
    @test isnothing(priority)

    priority = check_market_order_priority_with_order_id!(ob, 1, SELL_ORDER, 100.03)
    @test priority == 1
end

@testset "Test Ordermatching.jl -> raise_sidebook_priorty_via_display_property!" begin

    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,20)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end

    queues = VLLimitOrderBook._get_price_queue(ob.ask_orders, Float32(100.03))
    order_modified = raise_priorty_via_display_property!(ob, 13, SELL_ORDER, Float32(100.03), false)
    for i in 1 : 2
        @test queues.queue[i].display == false
    end
    @test order_modified  == 2
    order_modified = raise_priorty_via_display_property!(ob, 13, SELL_ORDER, Float32(100.99), false)
    @test order_modified  == 0
    order_modified = raise_priorty_via_display_property!(ob, 999, SELL_ORDER, Float32(100.03), false)
    @test order_modified  == 0
    order_modified = raise_priorty_via_display_property!(ob, 999, BUY_ORDER, Float32(100.03), false)
    @test order_modified  == 0
end

@testset "Test Ordermatching.jl -> reduce_priorty_via_display_property!" begin

    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,20)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    queues = VLLimitOrderBook._get_price_queue(ob.ask_orders, Float32(100.03))
    order_modified = reduce_priorty_via_display_property!(ob, 13, SELL_ORDER, Float32(100.03), false)
    
    @test queues.queue[3].display == false
    @test order_modified  == 1
    order_modified = reduce_priorty_via_display_property!(ob, 13, SELL_ORDER, Float32(100.99), false)
    @test order_modified  == 0
    order_modified = reduce_priorty_via_display_property!(ob, 999, SELL_ORDER, Float32(100.03), false)
    @test order_modified  == 0
    
    order_modified = reduce_priorty_via_display_property!(ob, 999, BUY_ORDER, Float32(100.03), false)
    @test order_modified  == 0
end

@testset "Test Ordermatching.jl -> elevate_priority!" begin

    ob = MyLOBType() #Initialize empty book
    order_info_lst = take(lmt_order_info_iter,20)
    # Add a bunch of orders
    for (orderid, price, size, side) in order_info_lst
        submit_limit_order!(ob,orderid,side,price,size,10101)
    end
    
    queues = VLLimitOrderBook._get_price_queue(ob.ask_orders, Float32(100.03))
    order_modified = raise_priorty_via_display_property!(ob, 13, SELL_ORDER, Float32(100.03), false)
    check_id = check_market_order_priority_with_order_id!(ob, 13, SELL_ORDER, Float32(100.03))
    need_higher_priority = elevate_priority!(ob, check_id, SELL_ORDER, Float32(100.03))
    @test need_higher_priority == false
    need_higher_priority = elevate_priority!(ob, 1, SELL_ORDER, Float32(100.03))
    @test need_higher_priority == true
    need_higher_priority = elevate_priority!(ob, 1, BUY_ORDER, Float32(99.97))
    @test need_higher_priority == false
    need_higher_priority = elevate_priority!(ob, 1, BUY_ORDER, Float32(99.93))
    @test need_higher_priority == true
end