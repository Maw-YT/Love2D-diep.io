local requestName, resultName = ...
local requestChannel = love.thread.getChannel(requestName or "shape_spawner_requests")
local resultChannel = love.thread.getChannel(resultName or "shape_spawner_results")

local function chooseType(x, y, width, height, mode)
    if mode == "TwoTeams" then
        local roll = math.random(1, 100)
        if roll <= 70 then return "square"
        elseif roll <= 95 then return "triangle"
        elseif roll <= 98 then return "pentagon"
        else return "hexagon" end
    end

    local nestSize = width * 0.15
    local centerX, centerY = width / 2, height / 2
    local inNest = math.abs(x - centerX) < nestSize / 2 and
                   math.abs(y - centerY) < nestSize / 2

    local rand = math.random(1, 100)
    if inNest then
        if rand <= 60 then return "pentagon"
        elseif rand <= 65 then return "alpha_pentagon"
        elseif rand <= 66 then return "hexagon"
        elseif rand <= 85 then return "crasher"
        else return "pentagon" end
    end

    if rand <= 70 then return "square"
    elseif rand <= 95 then return "triangle"
    elseif rand <= 98 then return "pentagon"
    else return "hexagon" end
end

while true do
    local req = requestChannel:demand()
    if req and req.op == "stop" then
        break
    end

    if req and req.op == "spawn" then
        local count = req.count or 1
        local width = req.width
        local height = req.height
        local mode = req.mode or "FFA"

        for _ = 1, count do
            local x, y
            if mode == "TwoTeams" then
                x = math.random(math.floor(width * 0.20), math.floor(width * 0.80))
                y = math.random(100, height - 100)
            else
                x = math.random(100, width - 100)
                y = math.random(100, height - 100)
            end

            resultChannel:push({
                x = x,
                y = y,
                type = chooseType(x, y, width, height, mode),
                isCrasher = false,
            })
        end
    end
end
