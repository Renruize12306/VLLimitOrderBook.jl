using WebSockets, Sockets, Serialization
import WebSockets:Response, Request
import DataStructures: Deque, Dict
import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}

# Custom Serialization of a Priority1 instance
function Serialization.serialize(s::AbstractSerializer, instance::Priority1)
    Serialization.writetag(s.io, Serialization.OBJECT_TAG)
    Serialization.serialize(s, Priority1)
    Serialization.serialize(s, instance.size)
    Serialization.serialize(s, instance.price)
    Serialization.serialize(s, instance.transcation_id)
    Serialization.serialize(s, instance.account_id)
    Serialization.serialize(s, instance.create_time)
    Serialization.serialize(s, instance.ip_address)
    Serialization.serialize(s, instance.port)
end

function notify(map, ip_address, port)
    println("current Ip is: ", ip_address)
    println("current port is: ", port)
    function coroutine(thisws)
         try
            if haskey(map, port)
                deque = map[port]
                if isempty(deque)
                    message = "Current queue is empty"
                    writeguarded(thisws, message)
                    println("from server posted: ", message, " at $(now())")
                end     
                while !isempty(deque)
                    cur = first(deque)
                    write_iob = IOBuffer()
                    serialize(write_iob, cur)
                    seekstart(write_iob)
                    content = read(write_iob)
                    println(typeof(content))
                    writeguarded(thisws, content)
                    println("from server posted: ", string(cur), " at $(now())")
                    popfirst!(deque)               
                end
            else
                message = "Port is not open"
                writeguarded(thisws, message)
                println("from server posted: ", message, " at $(now())")
            end
        catch exc 
            println(stacktrace())
            println(exc)
        end
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


p1 = Priority1(1, 10.0, 101, 0, now(),"192.168.1.1", 8087)
p2 = Priority1(2, 10.0, 101, 0, now(),"192.168.1.1", 8087)
p3 = Priority1(3, 10.0, 101, 0, now(),"192.168.1.1", 8087)
p4 = Priority1(4, 10.0, 101, 0, now(),"192.168.1.1", 8087)

dq1 = Deque{Priority1}()
isempty(dq1)
length(dq1)
push!(dq1, p1)
push!(dq1, p2)
push!(dq1, p3)

p5 = Priority1(1, 10.0, 101, 0, now(),"0.0.0.0", 8088)
p6 = Priority1(2, 10.0, 101, 0, now(),"0.0.0.0", 8088)
p7 = Priority1(3, 10.0, 101, 0, now(),"0.0.0.0", 8088)
p8 = Priority1(3, 10.0, 101, 0, now(),"0.0.0.0", 8088)
dq2 = Deque{Priority1}()
isempty(dq2)
length(dq2)
push!(dq2, p5)
push!(dq2, p6)
push!(dq2, p7)

p9 = Priority1(1, 10.0, 101, 0, now(),"11.11.11.11", 8089)
p10 = Priority1(2, 10.0, 101, 0, now(),"11.11.11.11", 8089)
p11 = Priority1(3, 10.0, 101, 0, now(),"11.11.11.11", 8089)
p12 = Priority1(3, 10.0, 101, 0, now(),"11.11.11.11", 8089)
dq3 = Deque{Priority1}()
isempty(dq3)
length(dq3)
push!(dq3, p9)
push!(dq3, p10)
push!(dq3, p11)

p13 = Priority1(1, 10.0, 101, 0, now(),"22.2.22.2", 8090)
p14 = Priority1(2, 10.0, 101, 0, now(),"22.2.22.2", 8090)
p15 = Priority1(3, 10.0, 101, 0, now(),"22.2.22.2", 8090)
p16 = Priority1(3, 10.0, 101, 0, now(),"22.2.22.2", 8090)
dq4 = Deque{Priority1}()
isempty(dq4)
length(dq4)
push!(dq4, p13)
push!(dq4, p14)
push!(dq4, p15)


map = Dict{Int, Deque{Priority1}}()
nums = [8087,8088,8089,8090]
dqs = [dq1, dq2, dq3, dq4]
for  s in 1:length(nums)
    if !haskey(map, nums[s])
        get!(map, nums[s]) do 
            dqs[s]
        end
    end
end

notify(map, string(Sockets.getipaddr()), 8087)
notify(map, string(Sockets.getipaddr()), 8088)
notify(map, string(Sockets.getipaddr()), 8089)
notify(map, string(Sockets.getipaddr()), 8090)
