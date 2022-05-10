using HTTP, Serialization

# @async HTTP.WebSockets.listen("127.0.0.1", UInt16(8083)) do ws
HTTP.WebSockets.listen("127.0.0.1", UInt16(8083)) do ws
    while !eof(ws)
        data = readavailable(ws)
        if length(data) > 0
            ds = deserialize(IOBuffer(data))
            println(ds)
            println(typeof(ds))
        end
    end
end