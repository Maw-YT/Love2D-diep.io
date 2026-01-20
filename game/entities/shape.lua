-- game/shape.lua
local Shape = {}
Shape.__index = Shape

local HealthBar = require "game.components.healthBar"

function Shape:newRandom(arena)
    local self = setmetatable({}, Shape)

    -- 1. Determine spawn position
    self.x = love.math.random(100, arena.width - 100)
    self.y = love.math.random(100, arena.height - 100)

    -- 2. Define the "Nest" (the center 25% of the map)
    local nestSize = arena.width * 0.15 
    local centerX, centerY = arena.width / 2, arena.height / 2
    
    local inNest = math.abs(self.x - centerX) < nestSize / 2 and 
                   math.abs(self.y - centerY) < nestSize / 2

    -- 3. Determine type based on location
    local rand = love.math.random(1, 100)
    if inNest then
        -- NEST SPAWNS: Pentagons, Hexagons, and Alpha Pentagons
        self.vx = 0
        self.vy = 0
        if rand <= 60 then
            self:setType("pentagon")
        elseif rand <= 65 then
            self:setType("alpha_pentagon")
        elseif rand <= 66 then
            self:setType("hexagon")
        else
            self:setType("pentagon")
        end
    else
        -- REGULAR SPAWNS: Assign movement velocity here
        self.vx = love.math.random(-25, 25)
        self.vy = love.math.random(-25, 25)
        if rand <= 70 then
            self:setType("square")
        elseif rand <= 95 then
            self:setType("triangle")
        elseif rand <= 98 then
            self:setType("pentagon")
        else
            self:setType("hexagon")
        end
    end
    self.passiveRotation = love.math.random(-1, 1)
    self.angle = love.math.random() * math.pi * 2
    self.driftSpeed = 50
    self.drag_strength = 2
    
    self.healthBar = HealthBar:new(self.health)
    self.hitTimer = 0
    return self
end

function Shape:update(dt, arena)
    -- Calculate current speed
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)

    -- ONLY apply drag if we are going faster than the drift speed
    if speed > self.driftSpeed then
        local drag_mag = self.drag_strength * speed * dt
        self.vx = self.vx - (self.vx / speed) * drag_mag
        self.vy = self.vy - (self.vy / speed) * drag_mag
        
        -- Optional: prevent undershooting the driftSpeed due to dt fluctuations
        local newSpeed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
        if newSpeed < self.driftSpeed then
            local ratio = self.driftSpeed / newSpeed
            self.vx = self.vx * ratio
            self.vy = self.vy * ratio
        end
    end

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

    -- Integrate velocity into position
    self.x = self.x + (self.vx * dt)
    self.y = self.y + (self.vy * dt)

    -- Passive Rotation
    self.angle = self.angle + (self.passiveRotation / 500)

    -- Countdown the hit timer
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end
    self.healthBar:update(dt, self.health)
end

function Shape:draw(alpha, style)
    local a = alpha or 1 -- Use provided alpha or default to solid
    local r, g, b = self.color[1], self.color[2], self.color[3]
    -- Pass alpha to health bar too
    if self.healthBar and self.healthBar.draw then
        self.healthBar:draw(self.x, self.y, self.size / 2, a)
    end

    local vertices = self:getVertices()

    -- HIT FLASH LOGIC
    -- Flash White for the first half, Red for the second half
    if self.hitTimer > 0 then
        if self.hitTimer > 0.1 then
            r, g, b = 1, 1, 1 -- White flash
        else
            r, g, b = 1, 0.3, 0.3 -- Red flash
        end
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    love.graphics.setLineJoin("bevel")
    love.graphics.setColor(r, g, b, a)
    love.graphics.polygon("fill", vertices)
    
    love.graphics.setLineWidth(3)
    if style == "New" then
        love.graphics.setColor(r*0.8, g*0.8, b*0.8, a)
    elseif style == "Old" then
        love.graphics.setColor(0.3, 0.3, 0.3, a)
    else
        love.graphics.setColor(r*0.8, g*0.8, b*0.8, a)
    end
    love.graphics.polygon("line", vertices)

    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin("miter")
    love.graphics.pop()
end

-- Helper to generate polygon vertices
function Shape:getVertices()
    local vertices = {}
    for i = 0, self.sides - 1 do
        local angle = (i / self.sides) * math.pi * 2
        table.insert(vertices, math.cos(angle) * (self.size / 2))
        table.insert(vertices, math.sin(angle) * (self.size / 2))
    end
    return vertices
end

function Shape:setType(type)
    self.type = type
    if type == "square" then
        local rand = love.math.random(1, 100)
        if rand <= 2 then
            -- Green Square
            self.sides, self.max_health, self.size = 4, 1000, 50
            self.color = {0.3, 0.9, 0.3}
        else
            self.sides, self.max_health, self.size = 4, 10, 50
            self.color = {0.9, 0.9, 0.2}
        end
    elseif type == "triangle" then
        local rand = love.math.random(1, 100)
        if rand <= 2 then
            -- Green Triangle
            self.sides, self.max_health, self.size = 3, 1500, 55
            self.color = {0.3, 0.9, 0.3}
        else
            self.sides, self.max_health, self.size = 3, 30, 55
            self.color = {0.9, 0.3, 0.3}
        end
    elseif type == "pentagon" then
        local rand = love.math.random(1, 100)
        if rand <= 2 then
            -- Green Pentagon
            self.sides, self.max_health, self.size = 5, 2250, 75
            self.color = {0.3, 0.9, 0.3}
        else
            self.sides, self.max_health, self.size = 5, 100, 75
            self.color = {0.5, 0.5, 0.9}
        end
    elseif type == "hexagon" then
        self.sides, self.max_health, self.size = 6, 500, 125
        self.color = {0.2, 0.7, 0.8}
    elseif type == "alpha_pentagon" then
        -- The "Boss" of the nest
        self.sides, self.max_health, self.size = 5, 3000, 250
        self.color = {0.4, 0.4, 0.9} -- Darker blue/purple
    end
    self.health = self.max_health
end

-- For collision
function Shape:getRadius()
    return self.size / 2.5
end

return Shape