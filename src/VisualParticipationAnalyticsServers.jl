module VisualParticipationAnalyticsServers

using DataFrames
using HTTP
using JSON3
using SQLite
using Tables

export start,
    startrest,
    startws

include("rest.jl")
include("websocket.jl")

"""
    start()
"""
function start()
    startrest()
    startws()
end

end
