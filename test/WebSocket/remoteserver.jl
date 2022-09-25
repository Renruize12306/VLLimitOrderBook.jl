using HTTP
using Dates
using Sockets
using Serialization
using VL_LimitOrderBook

# THIS SIMULATES BACKGROUND LOB/SERVER PROCESS

MyPriority = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}

"""
    Serialization.deserialize(s::AbstractSerializer, ::Type{MyPriority})

This function will deserialize the Priority instance from the WebSockets.

"""
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
port = 8082
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