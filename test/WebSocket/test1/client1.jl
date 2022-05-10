using HTTP


@async HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws
    while !eof(ws)
        data = readavailable(ws)
        println(data)
        println(typeof(data))
        println(String(data)) 
    end
end