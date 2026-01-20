-- game/init.lua
Game = {}

local Loader = require "game.utils.loader"

function Game:load()
    self.state = "MENU" -- Possible states: "MENU", "PLAYING", "PAUSED"
    self.style = "New"

    self.res = Loader.loadAll()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    self.ui = self.res.UIManager:new(self)

    -- Access classes via self.res
    self.CollisionManager = self.res.CollisionManager
    self.DeathManager = self.res.DeathManager
    self.camera = self.res.Camera:new()
    self.arena  = self.res.Arena:new(8000, 8000)

    self.dyingObjects = {}
    self.respawnTimer = 0
    self.arena:spawnInitialShapes(500)
end

function Game:startGame()
    -- Reset game logic
    self.player = self.res.Player:new(self.arena.width / 2, self.arena.height / 2)
    self.arena.shapes = {}
    self.dyingObjects = {}
    self.arena:spawnInitialShapes(500)
    self.state = "PLAYING"
end

function Game:update(dt)
    self.ui:update(dt, self.state)

    if self.state == "MENU" then
        for _, s in ipairs(self.arena.shapes) do s:update(dt, self.arena) end
    elseif self.state == "PLAYING" then
        -- ONLY update game logic if not paused
        if not self.player.isDead then
            self.player:update(dt, self.arena)
        else
            self.respawnTimer = self.respawnTimer - dt
            if self.respawnTimer <= 0 then self:respawnPlayer() end
        end

        for _, b in ipairs(self.player.bullets) do b:update(dt, self.arena) end
        for _, s in ipairs(self.arena.shapes) do s:update(dt, self.arena) end

        self.CollisionManager.updateAll(self, dt)
        self.DeathManager.update(self, dt)
        self.camera:follow(self.player.x, self.player.y, dt)
    
    elseif self.state == "PAUSED" then
        -- Logic is frozen here
    end
end

function Game:respawnPlayer()
    -- Create a new player instance at the center
    self.player = self.res.Player:new(self.arena.width / 2, self.arena.height / 2)
    -- Optional: Clear bullets from the previous life
    self.player.bullets = {} 
    -- Reset timer for future deaths
    self.respawnTimer = 5 
end

function Game:draw()

    local dt = love.timer.getDelta()
    -- 1. DRAW EVERYTHING
    love.graphics.push()
    self.camera:apply()
    
    self.arena:drawBackground()

    self.arena:drawShapes(self.style)
    
    if self.state == "PLAYING" or self.state == "PAUSED" then
        for _, b in ipairs(self.player.bullets) do b:draw(1, self.style) end
        if not self.player.isDead then
            self.player:draw(1, self.style)
        end
    end
    -- Draw dying things while camera is active
    for _, obj in ipairs(self.dyingObjects) do
        -- The apply function handles the setColor(1,1,1,self.alpha)
        if obj.type then
            obj.deathAnim:apply(function(a) obj:draw(a, self.style) end)
        else
            obj.deathAnim:apply(function(a) obj:draw(a) end)
        end
    end
    
    love.graphics.pop()

    -- 2. DRAW SCREEN SPACE (UI - stays fixed on your monitor)
    self.ui:draw(self.state, self.player)
end