using WebSockets
import WebSockets:Response, Request
using Dates
using Sockets
using Serialization

import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

MyPriority = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}

# Custom Deserialization of a Priority instance
function Serialization.deserialize(s::AbstractSerializer, ::Type{Priority})
    size = Serialization.deserialize(s)
    price = Serialization.deserialize(s)
    transcation_id = Serialization.deserialize(s)
    account_id = Serialization.deserialize(s)
    create_time = Serialization.deserialize(s)
    ip_address = Serialization.deserialize(s)
    port = Serialization.deserialize(s)
    MyPriority(size,price,transcation_id,account_id,create_time,ip_address,port)
end

function receive(ip_address, port)
    address = "http://" * ip_address * ":" * port
    WebSockets.HTTP.get(address)
    #=@async=# begin
        # try
            WebSockets.open("ws://" * ip_address * ":" * port) do ws_client
                while !eof(ws_client)
                    data, success = readguarded(ws_client)
                    if success
                        if data isa Vector{UInt8}
                            read_iob = IOBuffer(data)
                            cur = deserialize(read_iob)
                            println("received:", cur, " at $(now())")
                        end
                    # else
                    #     println("read ws failed.")
                    end
                end
        #     end;
        # catch exc
        #    println(stacktrace())
        #    println(exc)
        end
    end

end

receive(string(Sockets.getipaddr()), "8088")