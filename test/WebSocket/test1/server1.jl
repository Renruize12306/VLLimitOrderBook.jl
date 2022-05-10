using HTTP

HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws
    write(ws, "haha")
end;