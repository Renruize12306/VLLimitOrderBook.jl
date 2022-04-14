using WebSockets
import WebSockets:Response, Request
using Dates
using Sockets

import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String}

function receive(ip_address, port)
    address = "http://" * ip_address * ":" * port
    WebSockets.HTTP.get(address)
    #=@async=# begin
        try
            WebSockets.open("ws://" * ip_address * ":" * port) do ws_client
                while !eof(ws_client)
                    data, success = readguarded(ws_client)
                    if success
                        println(" received:", String(data), " at $(now())")
                    # else
                     #    println("read ws failed.")
                    end
                end
            end;
        catch exc
            println(stacktrace())
            println(exc)
        end
    end

end

# receive("10.243.16.28", "8088")
# receive("10.243.251.118", "8088")
receive("10.49.8.240", "8088")