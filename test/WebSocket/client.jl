using SimpleWebsockets

client = WebsocketClient()
ended = Condition()

listen(client, :connect) do ws
    listen(ws, :message) do message
        @info message
    end
    listen(ws, :close) do reason
        @warn "Websocket connection closed" reason...
        notify(ended)
    end
    for count = 1:10
        send(ws, "hello $count")
        sleep(1)
    end
    close(ws)
end
listen(client, :connectError) do err
    notify(ended, err, error = true)
end

@async open(client, "ws://127.0.0.1:8081")
wait(ended)