using WebSockets

serverWS = WebSockets.ServerWS((req) -> WebSockets.Response(200), (ws_server) -> (writeguarded(ws_server, "Hello"); readguarded(ws_server)))
# WebSockets.ServerWS(handler= #17(req), wshandler=#18(ws_server), connection_count=7)

ta = @async WebSockets.with_logger(WebSocketLogger()) do
    WebSockets.serve(serverWS, port = 8000)
end




#=
put!(serverWS.in, "close!")

ta
=#