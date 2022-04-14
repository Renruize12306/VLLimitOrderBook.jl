using WebSockets
import WebSockets:Response, Request
using Dates
using Sockets

import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String}

p1 = Priority1(1, 10.0, 101, 0, now(),"192.168.1.1")


function notify(data, ip_address, port)
    println("current Ip is: ", ip_address)
    println("current port is: ", port)
    function coroutine(thisws)
         # while true
            writeguarded(thisws, data)
            println("from server posted: ", data, " at $(now())")
         #     sleep(3)
         # end
        nothing
    end

    function gatekeeper(req, ws)
        orig = WebSockets.origin(req)
        if occursin(ip_address, orig) | occursin("", orig)
            coroutine(ws)
        else        
            @warn("Unauthorized websocket connection, $orig not approved by gatekeeper, expected $ip_address")
        end
        nothing
    end

    serverWS = WebSockets.ServerWS((req) -> WebSockets.Response(200), 
                                            gatekeeper)

    @async begin 
        try
            WebSockets.with_logger(WebSocketLogger()) do
                WebSockets.serve(serverWS, ip_address, port)
            end

        catch exc 
            println(stacktrace())
            println(exc)
        end
    end

end

# notify("xixihaha", string(Sockets.getipaddr()), 8000)
notify(string(p1), "10.243.16.28", 8088)
# notify("xixihaha", "10.243.16.28", 8088)

#=
WebSockets.HTTP.get("http://127.0.0.1:8000")

client_task = @async begin
    try
        WebSockets.open("ws://127.0.0.1:8000") do ws_client

            while !eof(ws_client)
                data, success = readguarded(ws_client)
                
                if success
                    println(" received:", String(data), " at $(now())")
                else
                    println("read ws failed.")
                end
            end
        end;
    catch exc
        println(stacktrace())
        println(exc)
    end
end
=#