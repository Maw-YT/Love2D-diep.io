-- game/shape.lua
local Shape = {}
Shape.__index = Shape

local Physics = require "game.system.physics"
local HealthBar = require "game.components.healthBar"

local BASE_ORBIT = 0.005
local BASE_ROTATION = 0.002 -- Derived from AI.PASSIVE_ROTATION reference

local greenColor = {0.5, 1, 0.4}

function Shape:newRandom(arena)
    local self = setmetatable({}, Shape)

    -- 1. Determine spawn position
    self.x = love.math.random(100, arena.width - 100)
    self.y = love.math.random(100, arena.height - 100)

    local nestSize = arena.width * 0.15 
    local centerX, centerY = arena.width / 2, arena.height / 2
    local inNest = math.abs(self.x - centerX) < nestSize / 2 and 
                   math.abs(self.y - centerY) < nestSize / 2

    self.vx = 0
    self.vy = 0

    -- DRIFT INITIALIZATION (Ref: AbstractShape.ts)
    -- orbitRate and rotationRate are randomized directions
    self.orbitRate = (love.math.random() < 0.5 and -1 or 1) * BASE_ORBIT
    self.passiveRotation = (love.math.random() < 0.5 and -1 or 1) * BASE_ROTATION
    self.orbitAngle = love.math.random() * math.pi * 2
    self.angle = self.orbitAngle -- Initial visual angle matches orbit

    local rand = love.math.random(1, 100)
    if inNest then
        if rand <= 60 then self:setType("pentagon")
        elseif rand <= 65 then self:setType("alpha_pentagon")
        elseif rand <= 66 then self:setType("hexagon")
        else self:setType("pentagon") end
    else
        if rand <= 70 then self:setType("square")
        elseif rand <= 95 then self:setType("triangle")
        elseif rand <= 98 then self:setType("pentagon")
        else self:setType("hexagon") end
    end

    self.healthBar = HealthBar:new(self.health)
    self.hitTimer = 0
    return self
end

function Shape:update(dt, arena)
    -- IDLE DRIFT LOGIC (Ref: AbstractShape.ts)
    -- 1. Update the orbit angle
    self.orbitAngle = self.orbitAngle + self.orbitRate

    -- 2. Maintain velocity in the direction of the orbit (Object.ts maintainVelocity)
    -- maintainVelocity adds velocity: maxSpeed * 0.1
    local driftForce = (self.shapeVelocity / (FRICTION * 35)) * 0.1
    self.vx = self.vx + math.cos(self.orbitAngle) * driftForce
    self.vy = self.vy + math.sin(self.orbitAngle) * driftForce

    -- Visual Rotation
    self.angle = self.angle + self.passiveRotation

    -- 3. Standard Physics (Friction and Arena Bounds)
    Physics.applyPhysics(self, dt)
    Physics.keepInArena(self, arena.width, arena.height)

    -- Countdown the hit timer
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end
    self.healthBar:update(dt, self.health, self.max_health)
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
    self.pushFactor = 1.0 
    self.absorptionFactor = 1.0

    self.shapeVelocity = 30 

    local rand = love.math.random(1, 100)
    
    if type == "square" then
        if rand <= 2 then -- GREEN SQUARE
            self.sides, self.max_health, self.size = 4, 1000, 50
            self.color = greenColor
            self.pushFactor, self.absorptionFactor = 3.0, 0.2
            self.shapeVelocity = 15 -- Rarities drift slower
        else
            self.sides, self.max_health, self.size = 4, 10, 50
            self.color = {1, 0.9, 0.4}
            self.absorptionFactor = 1.5 
        end
    elseif type == "triangle" then
        if rand <= 2 then -- GREEN TRIANGLE
            self.sides, self.max_health, self.size = 3, 1500, 55
            self.color = greenColor
            self.pushFactor, self.absorptionFactor = 4.0, 0.15
            self.shapeVelocity = 15
        else
            self.sides, self.max_health, self.size = 3, 30, 55
            self.color = {1, 0.5, 0.5}
            self.shapeVelocity = 30 -- Triangles are faster
        end
    elseif type == "pentagon" then
        if rand <= 2 then -- GREEN PENTAGON
            self.sides, self.max_health, self.size = 5, 2250, 75
            self.color = greenColor
            self.pushFactor, self.absorptionFactor = 5.0, 0.1
            self.shapeVelocity = 12
        else
            self.sides, self.max_health, self.size = 5, 100, 75
            self.color = {0.5, 0.6, 1}
            self.pushFactor = 1.5
            self.shapeVelocity = 18
        end
    elseif type == "hexagon" then
        self.sides, self.max_health, self.size = 6, 500, 125
        self.color = {0.2, 0.7, 0.8}
        self.pushFactor, self.absorptionFactor = 2.0, 0.5
        self.shapeVelocity = 10
    elseif type == "alpha_pentagon" then
        self.sides, self.max_health, self.size = 5, 3000, 250
        self.color = {0.5, 0.6, 1}
        self.pushFactor, self.absorptionFactor = 8.0, 0.05
        self.shapeVelocity = 5 -- Alpha pentagons barely move
    end
    self.health = self.max_health
end

-- For collision
function Shape:getRadius()
    return self.size / 2.5
end

return Shape