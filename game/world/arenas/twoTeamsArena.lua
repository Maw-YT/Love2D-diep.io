local Arena = require "game.world.arena"

local TwoTeamsArena = setmetatable({}, { __index = Arena })
TwoTeamsArena.__index = TwoTeamsArena

local BASE_RATIO = 0.20
local MIDDLE_MIN_RATIO = BASE_RATIO
local MIDDLE_MAX_RATIO = 1.0 - BASE_RATIO

local function randomMiddleX(width)
    local minX = math.floor(width * MIDDLE_MIN_RATIO)
    local maxX = math.floor(width * MIDDLE_MAX_RATIO)
    return love.math.random(minX, maxX)
end

local function randomTeamSpawn(width, height, team)
    local margin = 200
    if team == "blue" then
        return love.math.random(margin, math.floor(width * BASE_RATIO)), love.math.random(margin, height - margin)
    end
    return love.math.random(math.floor(width * MIDDLE_MAX_RATIO), width - margin), love.math.random(margin, height - margin)
end

function TwoTeamsArena:new(w, h, player)
    local self = Arena:new(w, h, player)
    setmetatable(self, TwoTeamsArena)
    self.gamemode = "TwoTeams"
    self.maxBots = 60
    self.maxShapes = 3000
    return self
end

function TwoTeamsArena:addShape(shape)
    shape.x = randomMiddleX(self.width)
    shape.y = love.math.random(100, self.height - 100)
    Arena.addShape(self, shape)
end

function TwoTeamsArena:drawBackground()
    Arena.drawBackground(self)

    local leftW = self.width * BASE_RATIO
    local midW = self.width * (MIDDLE_MAX_RATIO - MIDDLE_MIN_RATIO)
    local rightX = self.width * MIDDLE_MAX_RATIO

    -- Blue base zone (left)
    love.graphics.setColor(0.25, 0.45, 0.95, 0.18)
    love.graphics.rectangle("fill", 0, 0, leftW, self.height)

    -- Middle neutral shape zone
    love.graphics.setColor(0.65, 0.65, 0.65, 0.12)
    love.graphics.rectangle("fill", leftW, 0, midW, self.height)

    -- Red base zone (right)
    love.graphics.setColor(0.95, 0.25, 0.25, 0.18)
    love.graphics.rectangle("fill", rightX, 0, self.width - rightX, self.height)
end

function TwoTeamsArena:spawnBot(team)
    if #self.bots >= self.maxBots then return end

    local blueCount, redCount = 0, 0
    for _, bot in ipairs(self.bots) do
        if bot.team == "blue" then blueCount = blueCount + 1
        elseif bot.team == "red" then redCount = redCount + 1 end
    end

    local spawnTeam = team
    if spawnTeam ~= "blue" and spawnTeam ~= "red" then
        spawnTeam = (blueCount <= redCount) and "blue" or "red"
    end

    local x, y = randomTeamSpawn(self.width, self.height, spawnTeam)

    local bot = self.res.Bot:new(x, y, self)
    bot:setTeam(spawnTeam)
    if spawnTeam == "blue" then
        bot.color = {0.2, 0.5, 0.95}
        bot.outline_color = {0.14, 0.35, 0.665}
    else
        bot.color = {0.9, 0.25, 0.2}
        bot.outline_color = {0.63, 0.175, 0.14}
    end
    self:addBot(bot)
end

return TwoTeamsArena
