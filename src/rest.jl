const API_ROOT = "/api/v1"
const CLUSTERING_ROOT = "$(homedir())/datasets/participation/clusterings"
const DATASET_ROOT = "$(homedir())/datasets/participation/databases"
const DISTANCE_ROOT = "$(homedir())/datasets/participation/distances"
const HEADERS = [
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "GET; POST; OPTIONS",
    "Access-Control-Allow-Origin" => "*",
    "Content-Type" => "application/json"
]

"""
    getdatasets(req::HTTP.Request)
"""
function getdatasets(::HTTP.Request)
    names = readdir(DATASET_ROOT)
    filter!(endswith(".sqlite"), names)
    return names
end

"""
    getcontributions(req::HTTP.Request)
"""
function getcontributions(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    database = SQLite.DB("$DATASET_ROOT/$datasetname")
    return DBInterface.execute(database, "SELECT * FROM contribution ORDER BY id") |> DataFrame
end

"""
    getcontribution(req::HTTP.Request)
"""
function getcontribution(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    contributionid = HTTP.URIs.splitpath(req.target)[6]
    database = SQLite.DB("$DATASET_ROOT/$datasetname")
    return DBInterface.execute(database, "SELECT * FROM contribution WHERE id = $contributionid") |> DataFrame
end

"""
    getclusterings(req::HTTP.Request)
"""
function getclusterings(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    names = readdir("$CLUSTERING_ROOT/$datasetname")
    filter!(endswith(".json"), names)
    return names
end

"""
    getclustering(req::HTTP.Request)
"""
function getclustering(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    clustering = HTTP.URIs.splitpath(req.target)[6]
    return read("$CLUSTERING_ROOT/$datasetname/$clustering", String)
end

"""
    getdistances(req::HTTP.Request)
"""
function getdistances(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    names = readdir("$DISTANCE_ROOT/$datasetname")
    filter!(endswith(".json"), names)
    return names
end

"""
    getdistance(req::HTTP.Request)
"""
function getdistance(req::HTTP.Request)
    datasetname = HTTP.URIs.splitpath(req.target)[4]
    distance = HTTP.URIs.splitpath(req.target)[6]
    return read("$DISTANCE_ROOT/$datasetname/$distance", String)
end

router = HTTP.Router()
HTTP.@register(router, "GET", "$API_ROOT/datasets", getdatasets)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/clusterings", getclusterings)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/clustering/*", getclustering)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/contributions", getcontributions)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/contribution/*", getcontribution)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/distances", getdistances)
HTTP.@register(router, "GET", "$API_ROOT/datasets/*/distance/*", getdistance)

"""
    handlejson(req::HTTP.Request)
"""
function handlejson(req::HTTP.Request)
    res = HTTP.handle(router, req)
    code = 200
    if isa(res, HTTP.Response) && HTTP.iserror(res)
        code = convert(Int, HTTP.status(res))
        body = JSON3.write(HTTP.body(res))
    elseif Tables.istable(res)
        body = arraytable(res)
    elseif isa(res, String)
        body = res
    else
        body = JSON3.write(res)
    end
    return HTTP.Response(code, HEADERS; body=body)
end

"""
    handlecors(req::HTTP.Request)
"""
function handlecors(req::HTTP.Request)
    if HTTP.hasheader(req, "OPTIONS")
        return HTTP.Response(200, HEADERS)
    end
    return handlejson(req)
end

"""
    startrest(port::Integer)
"""
function startrest(port::Integer=3010)
    @async HTTP.serve(handlecors, HTTP.Sockets.localhost, port)
    println("REST server is running at http://$(HTTP.Sockets.localhost):$port")
end
