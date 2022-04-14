using WebSockets
# 10.243.251.118
# WebSockets.HTTP.get("http://127.0.0.1:8000")

WebSockets.open("ws://127.0.0.1:8000") do ws_client
    data, success = readguarded(ws_client)
    if success
        println(stderr, ws_client, " received:", String(data))
    end
end