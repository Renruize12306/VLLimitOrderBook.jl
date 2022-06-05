using WebSockets
import WebSockets:Response, Request
using Dates
using Sockets

function receive(ip_address, port)
    address = "http://" * ip_address * ":" * port
    # WebSockets.HTTP.get("http://127.0.0.1:8000")
                          #http://10.49.8.240:8000
    WebSockets.HTTP.get(address)
    #=@async=# begin
        try
            # WebSockets.open("ws://127.0.0.1:8000") do ws_client
            WebSockets.open("ws://" * ip_address * ":" * port) do ws_client
                while !eof(ws_client)
                    data, success = readguarded(ws_client)
                    # println( readguarded(ws_client))
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

end

# receive("10.49.43.127", "8000")
# receive("127.0.0.1", "8000") 
receive("10.49.8.240", "8000")
