local Player = {}
Player.__index = Player

local loader = require "game.utils.loader"
local Classes = require "game.data.classes"

function Player:new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.radius = 25
    self.angle = 0
    self.color = {0, 0.7, 1}
    self.outline_color = {0, 0.6, 0.9}
    self.res = loader.loadAll()

    -- Physics
    self.accel = 1500
    self.drag_strength = 10

    self.res = loader.loadAll()
    self.tankData = Classes.Tank -- Set default class
    self.tankName = self.tankData.name
    -- Barrels & Bullets
    -- Change self.barrel to a table of barrels
    -- Initialize barrels from the class definition
    self.barrels = {}
    for _, b in ipairs(self.tankData.barrels) do
        -- Pass 'b' as the 5th argument so Barrel:new receives the config
        table.insert(self.barrels, self.res.Barrel:new(self, b.offset, b.delay, b.type, b))
    end
    self.bullets = {}
    
    -- FIRING RATE FIX: Cooldown timer
    self.fire_rate = 0.4 -- Seconds between shots
    self.fire_timer = 0

    self.max_health = 100
    self.health = 100
    self.healthBar = self.res.HealthBar:new(self.max_health)
    self.hitTimer = 0

    self.regen_speed = 2
    
    self.level = 1
    self.xp = 0
    self.xpNextLevel = 100 -- Starting requirement
    self.statPoints = 0 -- Start with 0 points

    -- Current Stat Levels (max 8 each usually)
    self.stats = {
        movement_speed = 0,
        reload = 0,
        bullet_speed = 0,
        bullet_damage = 0,
        bullet_penetration = 0,
        max_health = 0
    }

    return self
end

function Player:update(dt, arena)
    -- LEVEL UP LOGIC
    if self.xp >= self.xpNextLevel then
        self.xp = self.xp - self.xpNextLevel
        self.level = self.level + 1
        self.xpNextLevel = math.floor(self.xpNextLevel * 1.2)
        
        -- Grant a stat point on level up
        self.statPoints = self.statPoints + 1
        self.xpBarReset = true 
    end

    -- MOUSE-BASED ANGLE
    local mx, my = love.mouse.getPosition()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self.angle = math.atan2(my - h/2, mx - w/2)

    -- Shooting logic
    if love.mouse.isDown(1) then
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

                -- ADD PLAYER RECOIL HERE
                local recoilForce = 150 -- Adjust this value for a stronger/weaker kick
                local pushAngle = self.angle + math.pi -- Opposite direction of aim
                
                self.vx = self.vx + math.cos(pushAngle) * recoilForce
                self.vy = self.vy + math.sin(pushAngle) * recoilForce
            end
        end
    else
        -- RESET: Start at 0 so the first click is Barrel 1 immediately
        self.fire_timer = 0
        for _, b in ipairs(self.barrels) do b.has_fired_this_cycle = false end
    end

    -- Movement physics
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1 end
    if love.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    if dx ~= 0 or dy ~= 0 then
        local input_len = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx / input_len, dy / input_len
        self.vx = self.vx + dx * self.accel * dt
        self.vy = self.vy + dy * self.accel * dt
    end

    -- Integrate
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- DIEP.IO STYLE BOUNDARY PUSHBACK
    local push_strength = 10 -- How hard the map pushes back
    
    -- Left and Right borders
    if self.x < 0 then
        -- The farther left you go, the harder it pushes Right
        self.vx = self.vx + math.abs(self.x) * push_strength * dt
    elseif self.x > arena.width then
        -- The farther right you go, the harder it pushes Left
        self.vx = self.vx - (self.x - arena.width) * push_strength * dt
    end

    -- Top and Bottom borders
    if self.y < 0 then
        self.vy = self.vy + math.abs(self.y) * push_strength * dt
    elseif self.y > arena.height then
        self.vy = self.vy - (self.y - arena.height) * push_strength * dt
    end
    
    -- PASSIVE REGEN
    -- Only regenerate if alive and below max health
    if self.health > 0 and self.health < self.max_health then
        self.health = self.health + (self.regen_speed * dt)
        
        -- Cap health at max_health
        if self.health > self.max_health then
            self.health = self.max_health
        end
    end

    -- Friction
    local speed = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    if speed > 0.1 then
        local drag_mag = self.drag_strength * speed * dt
        self.vx = self.vx - (self.vx / speed) * drag_mag
        self.vy = self.vy - (self.vy / speed) * drag_mag
    else
        self.vx, self.vy = 0, 0
    end

    -- Countdown the hit timer
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end
    self.healthBar:update(dt, self.health)
end

function Player:draw(alpha, style)
    local a = alpha or 1
    local r, g, b = self.color[1], self.color[2], self.color[3]
    local oR, oG, oB = nil, nil, nil
    if style == "New" then
        oR, oG, oB = self.outline_color[1], self.outline_color[2], self.outline_color[3]
    elseif style == "Old" then
        oR, oG, oB = 0.3, 0.3, 0.3
    else
        oR, oG, oB = self.outline_color[1], self.outline_color[2], self.outline_color[3]
    end

    local dt = love.timer.getDelta()

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    -- Draw every barrel in the table
    for _, barrel in ipairs(self.barrels) do
        barrel:draw(alpha, dt, style)
    end

    -- HIT FLASH LOGIC
    -- Flash White for the first half, Red for the second half
    if self.hitTimer > 0 then
        if self.hitTimer > 0.1 then
            r, g, b = 1, 1, 1 -- White flash
            if style == "New" then
                oR, oG, oB = 0.9, 0.9, 0.9
            elseif style == "Old" then
                oR, oG, oB = 0.3, 0.3, 0.3
            else
                oR, oG, oB = 0.9, 0.9, 0.9
            end
        else
            r, g, b = 1, 0.3, 0.3 -- Red flash
            if style == "New" then
                oR, oG, oB = 0.9, 0.2, 0.2
            elseif style == "Old" then
                oR, oG, oB = 0.3, 0.3, 0.3
            else
                oR, oG, oB = 0.9, 0.2, 0.2
            end
        end
    end

    if oR == nil then oR = 1 end
    if oG == nil then oG = 1 end
    if oB == nil then oB = 1 end

    -- Draw fill
    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", 0, 0, self.radius)

    -- Draw Outline
    love.graphics.setLineWidth(3)
    love.graphics.setColor(oR, oG, oB, a)
    love.graphics.circle("line", 0, 0, self.radius)

    -- Cleanup
    love.graphics.setLineWidth(1)
    love.graphics.pop()

    self.healthBar:draw(self.x, self.y, self.radius, a)
end

return Player