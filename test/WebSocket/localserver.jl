using HTTP
using Dates
using Sockets
using Serialization
using VL_LimitOrderBook

# THIS SIMULATES BACKGROUND LOB/SERVER PROCESS

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

# depreciated - from HTTP v0.9.17
# IPv4(0)
# # @async HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
# HTTP.WebSockets.listen("0.0.0.0", UInt16(8081)) do ws
# # HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
#     while !eof(ws)
#         data = readavailable(ws)
#         if length(data) > 0
#             ds = deserialize(IOBuffer(data))
#             println(ds)
#             println(typeof(ds))
#         end
#     end
# end

# using HTTP v1.0.5
server = HTTP.WebSockets.listen!("0.0.0.0", 8081) do ws
    println("Entering Loop")
    for msg in ws
        if length(msg) > 0
            ds = deserialize(IOBuffer(msg))
            println(ds)
            println(typeof(ds))
        end
    end
end