# don't include this file
# the original file for listening feature is not complete or have some bugs.
using WebSockets
import WebSockets:Response, Request
using Sockets

import VL_LimitOrderBook
using VL_LimitOrderBook, Random, Dates, Test

Priority1 = Priority{Int64, Float64, Int64, Int64, DateTime, String, Integer}

const LOCALIP = string(Sockets.getipaddr())
const PORT = 8087

const SERVER = Sockets.listen(Sockets.InetAddr(parse(IPAddr, LOCALIP), PORT))

task = @async try
    WebSockets.HTTP.listen(LOCALIP, PORT, server = SERVER, readtimeout = 0 ) do http
        if WebSockets.is_upgrade(http.message)
            WebSockets.upgrade(gatekeeper, http)
        else
            handle(handler_wrap, http)
        end
    end
catch err
    # Add your own error handling code; HTTP.jl sends error code to the client.
    @info err
    @info stacktrace(catch_backtrace())
end
