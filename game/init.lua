-- game/init.lua
Game = {}

local Loader = require "game.utils.loader"

function Game:load()
    local dt = love.timer.getDelta()

    self.state = "MENU" -- Possible states: "MENU", "PLAYING", "PAUSED"
    self.style = "New" -- Can be "New" or "Old"

    self.res = Loader.loadAll()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    self.ui = self.res.UIManager:new(self)

    -- Access classes via self.res
    self.CollisionManager = self.res.CollisionManager
    self.DeathManager = self.res.DeathManager
    self.arena  = self.res.Arena:new(22300, 22300)
    self.camera = self.res.Camera:new()
    self.player = nil

    self.dyingObjects = {}
    self.respawnTimer = 5
    self.arena:spawnInitialShapes(4000)
end

function Game:startGame()
    -- 1. Reset Global Game Logic
    self.arena.shapes = {}
    self.arena.bots = {}
    self.dyingObjects = {}
    
    -- 2. Initialize the Arena with baseline shapes
    self.arena:spawnInitialShapes(4000)

    -- 3. Respawn the Player 
    -- We call this before setting levels to ensure the object exists
    self:respawnPlayer()

    -- 4. Apply Gamemode Specific Logic
    if self.gamemode == "Sandbox" then
        -- NO BOTS
        self.arena.maxBots = 0
        -- Sandbox: Start at Level 45 with no bots
        self.player.level = 45
        -- Grant stat points (Level - 1)
        self.player.statPoints = 44
    else
        -- FFA: Normal progression (Level 1) and spawn bots
        -- Bots are only spawned in FFA mode per your requirement
        for _ = 1, 3 do
            self.arena:spawnBot()
        end
    end

    -- 5. Transition State
    self.state = "PLAYING"
end

function Game:update(dt)
    self.ui:update(dt, self.state)

    if self.state == "MENU" then
        self.arena:updateShapes(dt, self.camera)
        self.CollisionManager.updateAll(self, dt, self.state)
        self.arena:update(dt)
        self.camera:follow(self.arena.width/2, self.arena.height/2, dt, 1.0)
    elseif self.state == "PLAYING" then
        self.arena:update(dt)
        -- ONLY update game logic if not paused
        if self.player and not self.player.isDead then
            self.player:update(dt, self.arena, self.camera)
            -- CALCULATE ZOOM SCALE
            -- 25 is the starting radius. As player grows, scale decreases.
            local baseRadius = 25
            local targetScale = baseRadius / self.player.radius
            
            -- Limit how far it can zoom out (e.g., minimum 0.5x zoom)y
            targetScale = math.max(0.5, targetScale)
            self.camera:follow(self.player.x, self.player.y, dt, targetScale)
            self.player.lifeTime = self.player.lifeTime + dt
        else
            self.respawnTimer = self.respawnTimer - dt
            if self.respawnTimer <= 0 then self:respawnPlayer() end
            -- Reset zoom when dead
            self.camera:follow(self.arena.width/2, self.arena.height/2, dt, 1.0)
        end
        if self.player then
            for _, b in ipairs(self.player.bullets) do b:update(dt, self.arena, self.camera) end
        end
        self.arena:updateBots(dt, self.camera)
        for _, bot in ipairs(self.arena.bots) do
            for _, b in ipairs(bot.bullets) do b:update(dt, self.arena, self.camera) end
        end
        self.arena:updateShapes(dt, self.camera)

        self.CollisionManager.updateAll(self, dt, self.state)
        self.DeathManager.update(self, dt)
    
    elseif self.state == "PAUSED" then
        if self.player and not self.player.isdead then
            -- Logic is frozen here
            -- CALCULATE ZOOM SCALE
            -- 25 is the starting radius. As player grows, scale decreases.
            local baseRadius = 25
            local targetScale = baseRadius / self.player.radius
            
            -- Limit how far it can zoom out (e.g., minimum 0.5x zoom)
            targetScale = math.max(0.5, targetScale)
            self.camera:follow(self.player.x, self.player.y, dt, targetScale)
        end
    end
end

function Game:respawnPlayer()
    -- Define a margin so the player doesn't spawn exactly on the edge
    local margin = 100
    local spawnX = love.math.random(margin, self.arena.width - margin)
    local spawnY = love.math.random(margin, self.arena.height - margin)
    -- Create a new player instance at the random location
    self.player = nil
    self.arena.player = nil
    self.player = self.res.Player:new(spawnX, spawnY)
    self.arena.player = self.player
    self.player.active = false
    self.player.lifeTime = 0
    -- Optional: Clear bullets and drones from the previous life
    self.player.bullets = {}
    self.player.drones = {} 
    -- Reset timer for future deaths
    self.respawnTimer = 5 
end

function Game:draw()  
    local dt = love.timer.getDelta()  
    love.graphics.push()  
    self.camera:apply()  
      
    self.arena:drawBackground()  
    self.arena:drawShapes(1, self.style, self.camera)  

    if self.state == "PLAYING" or self.state == "PAUSED" then  
        for _, b in ipairs(self.player.bullets) do   
            b:draw(1, self.style)   
        end  
        if not self.player.isDead then  
            self.player:draw(1, self.style)  
        end
        self.arena:drawBots(1, self.style, self.camera)
        for _, bot in ipairs(self.arena.bots) do
            for _, b in ipairs(bot.bullets) do
                b:draw(1, self.style)
            end
        end
    end  
      
    for _, obj in ipairs(self.dyingObjects) do  
        if obj.type then  
            obj.deathAnim:apply(function(a) obj:draw(a, self.style) end)  
        else  
            obj.deathAnim:apply(function(a) obj:draw(a) end)  
        end  
    end  
      
    love.graphics.pop()  
    love.graphics.setColor(1,1,1)
    love.graphics.printf("FPS: ".. love.timer.getFPS(),0,0,100,"center")
    self.ui:draw(self.state, self.player)  
end
