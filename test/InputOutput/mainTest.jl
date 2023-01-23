#=
    put into main Function
=#
import VLLimitOrderBook
using VLLimitOrderBook, Random
using Test
using Base.Iterators: zip,cycle,take,filter

function main()
   MyLOBType = OrderBook{Int64, Float32, Int64, Int64}
   ob = MyLOBType()

   orderid_iter = Base.Iterators.countfrom(1)
   sign_iter = cycle([1,-1,1,-1])
   side_iter = ( s > 0 ? SELL_ORDER : BUY_ORDER for s in sign_iter )
   spread_iter = cycle([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]*1e-2)
   price_iter = ( Float32(99.0 + sgn*δ) for (δ,sgn) in zip(spread_iter,sign_iter) )
   size_iter = cycle([10, 11, 20, 21, 30, 31, 40, 41, 50, 51])

   lmt_order_info_iter = zip(orderid_iter,price_iter,size_iter,side_iter)

   order_info_lst = take(lmt_order_info_iter,12)
   # Add a bunch of orders
   for (orderid, price, size, side) in order_info_lst
       submit_limit_order!(ob,uob,orderid,side,price,size,10101)
   end
   for (orderid, price, size, side) in order_info_lst
       cancel_order!(ob,orderid,side,price)
   end

   order_info_lst = take(lmt_order_info_iter,6)


   for (orderid, price, size, side) in order_info_lst
       submit_limit_order!(ob,uob,orderid,side,price,size,10101)
   end

   file_name = "log.csv"
   io = open(file_name, "w");
   write_csv(io,ob)

   ob_test = MyLOBType()
   if (isfile(file_name))
       io = open(file_name, "r");
       process_file(io, ob_test, file_name)
   end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
