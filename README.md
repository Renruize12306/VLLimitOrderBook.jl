# VLOrderBook
`VLOrderBook.jl` simulates the dynamics of an [Order Book](https://www.investopedia.com/terms/o/order-book.asp). The code for this package was based on two previous codes:

* [LimitOrderBook.jl](https://github.com/p-casgrain/LimitOrderBook.jl)

## Extended Features
1. Some bug has been fixed for the original package "https://github.com/p-casgrain/LimitOrderBook.jl"

2. Function "write_csv" and "process_file" will save the current statue of orderbook, the files will be save as CSV file

3. There will be a notify feature send back to the client/broker. A more clear way to describe this progress is that, when a broker send a limit order, it may not get matched immediately. However, as long as it matched, it will be notified from matching enginer. For the detailed design, please refer to "test/WebSocket/test/client.jl".<br>
To start this feature, two processes (one as broker and the other as matching engine), need to be initiated. For how to use the matching engine, please refer to example code "test/FillType/test2.jl"