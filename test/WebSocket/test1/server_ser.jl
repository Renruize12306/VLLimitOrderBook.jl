using HTTP, Serialization

HTTP.WebSockets.open("ws://127.0.0.1:8083") do ws
    io = IOBuffer()
    serialize(io, "hello")
    s = take!(io)
    write(ws, s)
end;