using HTTP
using Dates
using Sockets
using Serialization
using VL_LimitOrderBook

# THIS SIMULATES BACKGROUND LOB/SERVER PROCESS
# include("test/WebSocket/remoteserver.jl")

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

# using HTTP v1.0.5
host_ip_address = Sockets.getipaddr()
port = 8081
server = HTTP.WebSockets.listen!(host_ip_address, port) do ws
    println("Entering Loop")
    for msg in ws
        if msg == "close"
            close(ws)
        elseif length(msg) > 0
            ds = deserialize(IOBuffer(msg))
            println(ds)
            println(typeof(ds))
        end
    end
end

# close(server)