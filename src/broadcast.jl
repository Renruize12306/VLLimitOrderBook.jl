using Dates, Base, DataStructures, Sockets
import Base: >, <, ==, !=, isless, <=, >=, !
abstract type Comparable end

"""
    _notify_all(set::SortedSet)

    This function will be used to broadcast the message as long as an order in order book matched

"""
function _notify_all(set::SortedSet)
    HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws
        io = IOBuffer()
        serialize(io, set)
        s = take!(io)
        Sockets.send(ws, s)
    end
end