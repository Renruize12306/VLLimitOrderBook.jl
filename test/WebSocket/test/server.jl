using HTTP
using WebSockets, Sockets, Serialization
import WebSockets:Response, Request
import DataStructures: Deque, Dict
import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test, DataStructures

MyPriority = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}
# Custom Serialization of a MyPriority instance
function Serialization.serialize(s::AbstractSerializer, instance::MyPriority)
    Serialization.writetag(s.io, Serialization.OBJECT_TAG)
    Serialization.serialize(s, MyPriority)
    Serialization.serialize(s, instance.size)
    Serialization.serialize(s, instance.price)
    Serialization.serialize(s, instance.transcation_id)
    Serialization.serialize(s, instance.account_id)
    Serialization.serialize(s, instance.create_time)
    Serialization.serialize(s, instance.ip_address)
    Serialization.serialize(s, instance.port)
end

cur = MyPriority(3, 10.0, 101, 0, now(),"22.2.22.2", 8090)

set = SortedSet{Priority}()
p1 = MyPriority(1, 10.0, 101, 0, now(),"192.168.1.1", 8087)
p2 = MyPriority(2, 10.0, 101, 0, now(),"192.168.1.1", 8087)
p3 = MyPriority(3, 10.0, 101, 0, now(),"192.168.1.1", 8087)
p4 = MyPriority(4, 10.0, 101, 0, now(),"192.168.1.1", 8087)

push!(set, p1)
push!(set, p2)
push!(set, p3)

HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws
    io = IOBuffer()
    serialize(io, set)
    s = take!(io)
    write(ws, s)
end;