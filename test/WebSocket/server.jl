using SimpleWebsockets

server = WebsocketServer()
ended = Condition() 

listen(server, :client) do client
    listen(client, :message) do message
        @info "Got a message" client = client.id message = message
        send(client, "Echo back at you: $message")
    end
end
listen(server, :connectError) do err
    notify(ended, err, error = true)
end
listen(server, :closed) do details
    @warn "Server has closed" details...
    notify(ended)
end

@async serve(server; verbose = true)
wait(ended)