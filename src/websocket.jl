const JOBS = Channel{String}(32)
const OUT = Channel{String}(32)

"""
    runjobs()
"""
function runjobs()
    while true
        job = take!(JOBS)
        if job == "job_rand_sleep"
            put!(OUT, """{ "payload": "Job started. This may take some time..." }""")
            result = 3 * rand()
            sleep(result)
            put!(OUT, """{ "payload": $result }""")
        end
    end
end

"""
    startws(port::Integer)
"""
function startws(port::Integer=3020, nthreads=Threads.nthreads())
    @async HTTP.listen(HTTP.Sockets.localhost, port) do http
        if HTTP.WebSockets.is_upgrade(http.message)
            HTTP.WebSockets.upgrade(http) do ws
                @sync begin
                    @async while !eof(ws)
                        msg = String(readavailable(ws))
                        put!(JOBS, msg)
                    end
                    @async while isopen(ws)
                        write(ws, take!(OUT))
                    end
                end
            end
        end
    end
    println("WebSocket server is running at http://$(HTTP.Sockets.localhost):$port")

    for _ = 1:nthreads
        @async runjobs()
    end
end
