using HTTP
using WebSockets
import WebSockets:Response, Request
using Dates
using Sockets
using Serialization

import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

MyPriority = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}

# Custom Deserialization of a Priority instance
function Serialization.deserialize(s::AbstractSerializer, ::Type{MyPriority})
    size = Serialization.deserialize(s)
    price = Serialization.deserialize(s)
    transcation_id = Serialization.deserialize(s)
    account_id = Serialization.deserialize(s)
    create_time = Serialization.deserialize(s)
    ip_address = Serialization.deserialize(s)
    port = Serialization.deserialize(s)
    MyPriority(size,price,transcation_id,account_id,create_time,ip_address,port)
end


# @async HTTP.WebSockets.listen("127.0.0.1", UInt16(8084)) do ws
HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
    while !eof(ws)
        data = readavailable(ws)
        if length(data) > 0
            ds = deserialize(IOBuffer(data))
            println(ds)
            println(typeof(ds))
        end
    end
end