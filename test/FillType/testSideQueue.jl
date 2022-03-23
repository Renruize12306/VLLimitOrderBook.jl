import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test
using Base.Iterators: zip,cycle,take,filter

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String}

MyUOBType = UnmatchedOrderBook{Int64, Float64, Int64, Int64, DateTime, String}
uob = MyUOBType()

p1 = Priority1(1, 10.0, 101, 0, now(),"192.168.1.1")
p2 = Priority1(1, 10.0, 102, 0, now(),"192.168.2.1")
p3 = Priority1(1,19.0,103, 0,now(),"192.268.1.1")
p4 = Priority1(5,10.0,104, 0,now(),"192.268.1.1")
p5 = Priority1(2,10.0,105, 0,now(),"192.2.1.1")
p6 = Priority1(1,10.0,106, 0,now(),"192.268.100.1")

insert_unmatched_order!(uob.ask_unmatched_orders, p1)
insert_unmatched_order!(uob.ask_unmatched_orders, p2)
insert_unmatched_order!(uob.ask_unmatched_orders, p3)
insert_unmatched_order!(uob.ask_unmatched_orders, p4)
insert_unmatched_order!(uob.ask_unmatched_orders, p5)
insert_unmatched_order!(uob.ask_unmatched_orders, p6)

insert_unmatched_order!(uob.bid_unmatched_orders, p1)
insert_unmatched_order!(uob.bid_unmatched_orders, p2)
insert_unmatched_order!(uob.bid_unmatched_orders, p3)
insert_unmatched_order!(uob.bid_unmatched_orders, p4)
insert_unmatched_order!(uob.bid_unmatched_orders, p5)
insert_unmatched_order!(uob.bid_unmatched_orders, p6)


#=
Ask
OneSideUnmatchedBook{Int64, Float64, Int64, Int64, DateTime, String}(false, SortedSet(Priority{Int64, Float64, Int64, Int64, DateTime, String}
[Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 101, 0, DateTime("2022-03-22T16:51:43.589"), "192.168.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 102, 0, DateTime("2022-03-22T16:51:43.592"), "192.168.2.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 104, 0, DateTime("2022-03-22T16:51:43.593"), "192.268.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 106, 0, DateTime("2022-03-22T16:51:43.593"), "192.268.100.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(2, 10.0, 105, 0, DateTime("2022-03-22T16:51:43.593"), "192.2.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 19.0, 103, 0, DateTime("2022-03-22T16:51:43.593"), "192.268.1.1")],
Base.Order.ForwardOrdering()), 7, 6, 10.0)

SortedSet(Priority
[Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 101, 0, DateTime("2022-03-22T17:41:18.784"), "192.168.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 102, 0, DateTime("2022-03-22T17:41:18.805"), "192.168.2.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 104, 0, DateTime("2022-03-22T17:41:18.805"), "192.268.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 106, 0, DateTime("2022-03-22T17:41:18.806"), "192.268.100.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(2, 10.0, 105, 0, DateTime("2022-03-22T17:41:18.806"), "192.2.1.1")], 
Base.Order.ForwardOrdering())


Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 101, 0, DateTime("2022-03-22T17:55:57.538"), "192.168.1.1")
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 102, 0, DateTime("2022-03-22T17:55:57.542"), "192.168.2.1")
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 104, 0, DateTime("2022-03-22T17:55:57.542"), "192.268.1.1")
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, 10.0, 106, 0, DateTime("2022-03-22T17:55:57.542"), "192.268.100.1")
=#

# working with ask orders
p7 = Priority1(10,11.0,106, 0,now(),"192.268.100.1")
pop_unmatched_order_withinfilter!(uob.ask_unmatched_orders, p7)


#=
Bid
OneSideUnmatchedBook{Int64, Float64, Int64, Int64, DateTime, String}(true, SortedSet(Priority{Int64, Float64, Int64, Int64, DateTime, String}
[Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, -19.0, 103, 0, DateTime("2022-03-22T16:51:43.593"), "192.268.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, -10.0, 101, 0, DateTime("2022-03-22T16:51:43.589"), "192.168.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, -10.0, 102, 0, DateTime("2022-03-22T16:51:43.592"), "192.168.2.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, -10.0, 104, 0, DateTime("2022-03-22T16:51:43.593"), "192.268.1.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(1, -10.0, 106, 0, DateTime("2022-03-22T16:51:43.593"), "192.268.100.1"), 
Priority{Int64, Float64, Int64, Int64, DateTime, String}(2, -10.0, 105, 0, DateTime("2022-03-22T16:51:43.593"), "192.2.1.1")],
Base.Order.ForwardOrdering()), 7, 6, 19.0)


=#

# p8 = Priority1(6,11.0,106, 0,now(),"192.268.100.1")
# pop_unmatched_order_withinfilter!(uob.bid_unmatched_orders, p8)