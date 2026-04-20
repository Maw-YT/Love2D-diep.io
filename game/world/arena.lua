-- game/system/arena.lua
local Arena = {}
Arena.__index = Arena

local loader = require "game.utils.loader"
local EntityManager = require "game.system.entityManager"

function Arena:new(w, h, player)
    local self = setmetatable({}, Arena)
    self.width = w
    self.height = h
    self.padding = 1500
    self.player = player or nil
    self.shapes = {} -- Shapes now live here!
    self.bots = {}   -- AI tanks
    self.bosses = {} -- Boss entities (max 1)
    self.entityManager = EntityManager.new()
    self.res = loader.loadAll()

    -- Added a constant for the maximum population
    self.maxShapes = 4000
    self.maxBots = 199
    self.maxBosses = 1
    self.bossSpawnInterval = 45
    self.bossSpawnTimer = 0

    -- Multithreaded shape spawn worker.
    local uniqueId = tostring(self):gsub("[^%w]", "_")
    self._shapeSpawnRequestChannelName = "shape_spawner_requests_" .. uniqueId
    self._shapeSpawnResultChannelName = "shape_spawner_results_" .. uniqueId
    self._shapeSpawnRequestChannel = love.thread.getChannel(self._shapeSpawnRequestChannelName)
    self._shapeSpawnResultChannel = love.thread.getChannel(self._shapeSpawnResultChannelName)
    self._shapeSpawnRequestChannel:clear()
    self._shapeSpawnResultChannel:clear()
    self._pendingSpawnJobs = 0
    self._shapeSpawnerThread = love.thread.newThread("game/system/threads/shapeSpawner.lua")
    self._shapeSpawnerThread:start(self._shapeSpawnRequestChannelName, self._shapeSpawnResultChannelName)
    return self
end

function Arena:addShape(shape)
    table.insert(self.shapes, shape)
    self.entityManager:add(shape)
end

function Arena:addBot(bot)
    table.insert(self.bots, bot)
    self.entityManager:add(bot)
end

function Arena:addBoss(boss)
    table.insert(self.bosses, boss)
    self.entityManager:add(boss)
end

-- Spawn a single bot away from the player
function Arena:spawnBot()
    if #self.bots >= self.maxBots then return end
    local margin = 200
    local x = love.math.random(margin, self.width - margin)
    local y = love.math.random(margin, self.height - margin)
    if self.player and not self.player.isDead then
        local dx = x - self.player.x
        local dy = y - self.player.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 600 then return end
    end
    self:addBot(self.res.Bot:new(x, y, self))
end

function Arena:spawnBoss()
    if #self.bosses >= self.maxBosses then return end
    -- Center spawn for easier testing (camera / travel to boss).
    local x = self.width / 2
    local y = self.height / 2
    self:addBoss(self.res.Boss:new(x, y))
    if self.game and self.game.notificationSystem then
        self.game.notificationSystem:notifyBossSpawned()
    end
end

-- New function to maintain the shape population
function Arena:update(dt)
    -- Consume completed threaded spawn jobs first.
    while true do
        local spawnData = self._shapeSpawnResultChannel:pop()
        if not spawnData then break end
        self._pendingSpawnJobs = math.max(0, self._pendingSpawnJobs - 1)
        self:addShape(self.res.Shape:newFromSpawnData(spawnData, self))
    end

    -- Maintain bot count (only when game has a player, i.e. PLAYING)
    if self.player and not self.player.isDead and #self.bots < self.maxBots then
        if not self.botSpawnTimer then self.botSpawnTimer = 0 end
        self.botSpawnTimer = self.botSpawnTimer + dt
        if self.botSpawnTimer >= 4 then
            self.botSpawnTimer = 0
            self:spawnBot()
        end
    end
    -- Check if we are below the limit
    if #self.shapes < self.maxShapes then
        -- Calculate how many need to be spawned
        local needed = self.maxShapes - (#self.shapes + self._pendingSpawnJobs)
        
        -- You can spawn them all at once, or limit it per frame 
        -- to prevent a performance spike (e.g., spawn 5 per frame)
        local spawnCount = math.min(needed, 5) 

        if spawnCount > 0 then
            self._shapeSpawnRequestChannel:push({
                op = "spawn",
                count = spawnCount,
                width = self.width,
                height = self.height,
                mode = self.gamemode or "FFA",
            })
            self._pendingSpawnJobs = self._pendingSpawnJobs + spawnCount
        end
    end

    if self.player and not self.player.isDead and #self.bosses < self.maxBosses then
        self.bossSpawnTimer = self.bossSpawnTimer + dt
        if self.bossSpawnTimer >= self.bossSpawnInterval then
            self.bossSpawnTimer = 0
            self:spawnBoss()
        end
    end
end

function Arena:drawBackground()
    -- 1. Draw a dark background first (no mans land)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", 
        -self.padding, 
        -self.padding, 
        self.width + (self.padding * 2), 
        self.height + (self.padding * 2)
    )

    -- Light background
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    local nestSize = self.width * 0.15
    love.graphics.setColor(0.5, 0.5, 0.9, 0.25) -- Purple tint
    love.graphics.rectangle("fill", 
        (self.width / 2) - (nestSize / 2), 
        (self.height / 2) - (nestSize / 2), 
        nestSize, 
        nestSize
    )
    
    -- Light grid
    love.graphics.setColor(0, 0, 0, 0.05) -- ALMOST INVISALBE
    local step = 25
    -- Vertical lines
    for x = -self.padding, self.width + self.padding, step do
        love.graphics.line(x, -self.padding, x, self.height + self.padding)
    end
    -- Horizontal lines
    for y = -self.padding, self.height + self.padding, step do
        love.graphics.line(-self.padding, y, self.width + self.padding, y)
    end

    love.graphics.setLineWidth(1)
end

function Arena:spawnInitialShapes(count)
    for i = 1, count do
        self:addShape(self.res.Shape:newRandom(self))
    end
end

function Arena:dispose()
    if self._shapeSpawnRequestChannel then
        self._shapeSpawnRequestChannel:push({ op = "stop" })
    end
end

-- Shape Drawing with Culling
function Arena:drawShapes(alpha, style, camera)  
    -- Calculate viewport bounds with padding for shapes partially visible  
    local screenW = love.graphics.getWidth()  
    local screenH = love.graphics.getHeight()  
    local padding = 100 -- Extra space for shapes near edges  
      
    local minX = camera.x - padding  
    local maxX = camera.x + (screenW / camera.scale) + padding  
    local minY = camera.y - padding  
    local maxY = camera.y + (screenH / camera.scale) + padding  
    for _, s in ipairs(self.shapes) do
        if s.isDead or s.isdead then
            goto continue
        end
        -- Only draw if shape is within viewport  
        if s.x + s.size >= minX and s.x - s.size <= maxX and  
           s.y + s.size >= minY and s.y - s.size <= maxY then  
            s:draw(alpha, style)  
        end
        ::continue::
    end
end

function Arena:updateShapes(dt, camera)  
    -- Calculate viewport bounds with padding for shapes partially visible  
    local screenW = love.graphics.getWidth()  
    local screenH = love.graphics.getHeight()  
    local padding = 100 -- Extra space for shapes near edges  
      
    local minX = camera.x - padding  
    local maxX = camera.x + (screenW / camera.scale) + padding
    local minY = camera.y - padding  
    local maxY = camera.y + (screenH / camera.scale) + padding
    for i = #self.shapes, 1, -1 do
        local s = self.shapes[i]
        if s.isDead or s.isdead then
            -- Failsafe: if a shape is being removed while dead, make sure it
            -- has a death animation queued so visuals stay consistent.
            if self.game and self.game.dyingObjects and self.game.res and self.game.res.Animation then
                local alreadyQueued = false
                for j = 1, #self.game.dyingObjects do
                    if self.game.dyingObjects[j] == s then
                        alreadyQueued = true
                        break
                    end
                end
                if not alreadyQueued and not s.deathAnim then
                    s.deathAnim = self.game.res.Animation:new(s)
                    table.insert(self.game.dyingObjects, s)
                end
            end

            table.remove(self.shapes, i)
            if self.entityManager then
                self.entityManager:remove(s)
            end
        else
            s:update(dt, self)
        end
    end
end

function Arena:updateBots(dt, camera)
    for _, bot in ipairs(self.bots) do
        bot:update(dt, self, camera)
    end
end

function Arena:updateBosses(dt, camera)
    for _, boss in ipairs(self.bosses) do
        boss:update(dt, self, camera)
    end
end

function Arena:drawBots(alpha, style, camera)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local padding = 100
    local minX = camera.x - padding
    local maxX = camera.x + (screenW / camera.scale) + padding
    local minY = camera.y - padding
    local maxY = camera.y + (screenH / camera.scale) + padding
    for _, bot in ipairs(self.bots) do
        if bot.x + bot.radius >= minX and bot.x - bot.radius <= maxX and
           bot.y + bot.radius >= minY and bot.y - bot.radius <= maxY then
            bot:draw(alpha, style)
        end
    end
end

function Arena:drawBosses(alpha, style, camera)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local padding = 140
    local minX = camera.x - padding
    local maxX = camera.x + (screenW / camera.scale) + padding
    local minY = camera.y - padding
    local maxY = camera.y + (screenH / camera.scale) + padding
    for _, boss in ipairs(self.bosses) do
        if boss.x + boss.radius >= minX and boss.x - boss.radius <= maxX and
           boss.y + boss.radius >= minY and boss.y - boss.radius <= maxY then
            boss:draw(alpha, style)
        end
    end
end

return Arena