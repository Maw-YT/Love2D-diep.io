local Player = {}
Player.__index = Player

local loader = require "game.utils.loader"
local Classes = require "game.data.classes"
local Physics = require "game.system.physics"

function Player:new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.radius = 25
    self.angle = 0
    self.color = {0, 0.7, 0.9}
    self.outline_color = {0, 0.5, 0.7}
    self.res = loader.loadAll()

    -- Factors for the new collision system
    self.pushFactor = 2.0
    self.absorptionFactor = 1 -- Players are "heavier" than small shapes

    -- Diep.io friction balance: acceleration * 10 = max speed
    -- We'll use a standard value that Physics.applyPhysics will damp
    self.accel = 1500

    self.res = loader.loadAll()
    self.tankData = Classes.Tank 
    self.tankName = self.tankData.name
    
    self.barrels = {}
    for _, b in ipairs(self.tankData.barrels) do
        table.insert(self.barrels, self.res.Barrel:new(self, b.delay, b.type, b))
    end
    self.bullets = {}
    self.drones = {} -- Track active drones
    
    self.fire_rate = self.tankData.fire_rate or 0.4 
    self.fire_timer = 0

    self.max_health = 100
    self.health = 100
    self.healthBar = self.res.HealthBar:new(self.max_health)
    self.hitTimer = 0

    self.regen_speed = 2
    
    self.level = 1
    self.xp = 0
    self.xpNextLevel = 100 
    self.statPoints = 0 
    self.autoFire = false
    self.autoSpin = false
    self.justSpawned = true

    -- INVISIBILITY STATE
    self.invisAlpha = 1.0 -- 1 = visible, 0 = hidden

    self.stats = {
        movement_speed = 0,
        reload = 0,
        bullet_speed = 0,
        bullet_damage = 0,
        bullet_penetration = 0,
        max_health = 0,  
        body_damage = 0,
        health_regen = 0
    }

    return self
end

function Player:update(dt, arena, cam)
    self.radius = 25 + ((self.level - 1))
    self.accel = (25 + (2.5 * (self.stats.movement_speed + 1)) / (FRICTION * 30)) / dt
    
    -- LEVEL UP LOGIC
    if self.xp >= self.xpNextLevel then
        self.xp = self.xp - self.xpNextLevel
        self.level = self.level + 1
        self.xpNextLevel = math.floor(self.xpNextLevel * 1.2)
        self.statPoints = self.statPoints + 1
        self.xpBarReset = true 
    end

    local dx, dy = 0, 0
    -- KEYBOARD/MOUSE
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    

    -- TOGGLE INPUTS
    if love.keyboard.isDown("e") and not self.e_pressed then
        self.autoFire = not self.autoFire
    end
    self.e_pressed = love.keyboard.isDown("e")

    if love.keyboard.isDown("c") and not self.c_pressed then
        self.autoSpin = not self.autoSpin
    end
    self.c_pressed = love.keyboard.isDown("c")

    if not love.mouse.isDown(1) and self.justSpawned then self.justSpawned = false end
    -- ANGLE LOGIC
    if self.autoSpin then  
        self.angle = self.angle + (2 * dt)  
    else  
        local mx, my = love.mouse.getPosition()  
        local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()  
        local wx = (mx - sw / 2) / cam.scale + cam.x + (sw / 2) / cam.scale  
        local wy = (my - sh / 2) / cam.scale + cam.y + (sh / 2) / cam.scale  
        self.angle = math.atan2(wy - self.y, wx - self.x)  
    end

    -- SHOOTING LOGIC
    local isFiring = self.justSpawned == false and self.autoFire or love.mouse.isDown(1)
    if isFiring then
        self.fire_timer = self.fire_timer - dt
        if self.fire_timer <= 0 then
            self.fire_timer = self.fire_rate
            for _, b in ipairs(self.barrels) do b.has_fired_this_cycle = false end
        end

        local progress = 1 - (self.fire_timer / self.fire_rate)
        for _, barrel in ipairs(self.barrels) do
            if progress >= barrel.fire_delay and not barrel.has_fired_this_cycle then
                table.insert(self.bullets, barrel:fire())
                barrel.has_fired_this_cycle = true
                
                local recoilForce = 150 
                local barrelAngle = self.angle + (barrel.angleOffset or 0)
                local pushAngle = barrelAngle + math.pi
                local recoilMult = barrel.config.recoilMult or 1.0
                self.vx = self.vx + math.cos(pushAngle) * recoilForce * recoilMult
                self.vy = self.vy + math.sin(pushAngle) * recoilForce * recoilMult
            end
        end
    else
        if self.fire_timer > 0 then self.fire_timer = self.fire_timer - dt
        else self.fire_timer = 0 end
    end

    local isMoving = (dx ~= 0 or dy ~= 0)
    if isMoving then
        local input_len = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx / input_len, dy / input_len
        -- Instead of setting velocity, we add it. 
        -- Physics.applyPhysics friction will cap the speed.
        self.vx = self.vx + dx * self.accel * dt
        self.vy = self.vy + dy * self.accel * dt
    end

    -- INVISIBILITY LOGIC (Manager specific)
    if self.tankData.canInvisibility then
        -- If moving or firing, become visible quickly
        if isMoving or isFiring then
            self.invisAlpha = math.min(1, self.invisAlpha + dt * 5)
        else
            -- If stationary and not firing, fade out slowly
            self.invisAlpha = math.max(0, self.invisAlpha - dt * 1.5)
        end
    else
        self.invisAlpha = 1.0
    end

    -- NEW UNIFIED PHYSICS CALLS
    Physics.applyPhysics(self, dt)
    Physics.keepInArena(self, arena.width, arena.height)
    
    -- Passive Regen (base 2 + 1 per level)  
    if self.health > 0 and self.health < self.max_health then  
        local regenRate = self.regen_speed + self.stats.health_regen  
        self.health = math.min(self.max_health, self.health + (regenRate * dt))  
    end

    if self.hitTimer > 0 then self.hitTimer = self.hitTimer - dt end

    -- Max Drones Check
    local maxAllowed = self.tankData.maxDrones or 8 -- Default to 8 if not specified
    while #self.drones > maxAllowed do
        local oldestDrone = table.remove(self.drones, 1)
        oldestDrone.isdead = true -- Flag for removal from the game world
    end
    self.healthBar:update(dt, self.health, self.max_health)
end

function Player:draw(alpha, style)
    -- Blend requested alpha with current invisibility alpha
    local finalAlpha = (alpha or 1) * self.invisAlpha
    
    -- If fully invisible, don't draw anything (optional: keep health bar slightly visible)
    if finalAlpha <= 0 then return end

    local r, g, b = self.color[1], self.color[2], self.color[3]
    local oR, oG, oB = self.outline_color[1], self.outline_color[2], self.outline_color[3]
    
    if style == "Old" then oR, oG, oB = 0.3, 0.3, 0.3 end

    local dt = love.timer.getDelta()

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    
    for _, barrel in ipairs(self.barrels) do
        barrel:draw(finalAlpha, dt, style)
    end

    if self.hitTimer > 0 then
        if self.hitTimer > 0.1 then 
            r, g, b = 1, 1, 1
            if style == "New" then oR, oG, oB = 0.8, 0.8, 0.8 end
        else 
            r, g, b = 1, 0.3, 0.3 
            if style == "New" then oR, oG, oB = 0.8, 0.1, 0.1 end
        end
    end

    -- Draw fill & Outline
    love.graphics.setColor(r, g, b, finalAlpha)
    love.graphics.circle("fill", 0, 0, self.radius)
    love.graphics.setLineWidth(3)
    love.graphics.setColor(oR or 0, oG or 0, oB or 0, finalAlpha)
    love.graphics.circle("line", 0, 0, self.radius)
    love.graphics.pop()

    -- Only draw health bar if not fully hidden
    if self.invisAlpha > 0.5 then
        self.healthBar:draw(self.x, self.y, self.radius, finalAlpha)
    end
end

return Player