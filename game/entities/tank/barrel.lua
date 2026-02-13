-- game/barrel.lua
local Barrel = {}
Barrel.__index = Barrel
local loader = require "game.utils.loader"
local pi2 = (math.pi / 2)

function Barrel:new(player, fire_delay, bulletType, config, barrelBase)
    local self = setmetatable({}, Barrel)
    self.player = player
    self.barrelBase = barrelBase or player
    self.bulletType = bulletType or "bullet"
    self.fire_delay = fire_delay or 0
    self.has_fired_this_cycle = false
    self.recoilOffset = 0
    self.maxRecoil = 12
    self.res = loader.loadAll()

    self.config = config or {}
    self.angleOffset = self.config.angleOffset or 0
    
    -- Store multipliers instead of fixed values
    self.widthMult = self.config.widthMult or 0.7
    self.lengthMult = self.config.lengthMult or 1.3
    self.yOffsetMult = self.config.yOffsetMult or 0.4
    
    -- Normalize xOffset relative to a base radius of 25
    self.xOffsetMult = (self.config.xOffset or 0) / 25

    self.bulletSize = self.config.bulletSize or 1.0
    self.isTrapezoid = self.config.isTrapezoid or false
    self.tipWidthMult = self.config.tipWidth or 1.0

    self.spread = config.spread or 0.05
    self.color = {0.6, 0.6, 0.6}
    self.outline_color = {0.5, 0.5, 0.5}
    self.outline_thickness = 3.0
    return self
end

function Barrel:fire()
    self.recoilOffset = self.maxRecoil

    -- Calculate dynamic dimensions
    local currentYOffset = self.barrelBase.radius * self.yOffsetMult
    local currentLength = self.barrelBase.radius * self.lengthMult
    local currentXOffset = -(self.xOffsetMult * self.player.radius)
    
    local combinedAngle = self.barrelBase.angle + self.angleOffset
    local spawnDist = self.barrelBase.radius + currentLength - currentYOffset
    
    local bx = self.barrelBase.x + math.cos(combinedAngle) * spawnDist + math.sin(combinedAngle) * currentXOffset
    local by = self.barrelBase.y + math.sin(combinedAngle) * spawnDist - math.cos(combinedAngle) * currentXOffset
    
    -- Apply spread to the combined angle
    local finalAngle = combinedAngle + (love.math.random() - 0.5) * 2 * self.spread
    
    -- Rest of the velocity math stays the same, using finalAngle
    local vx = (math.cos(finalAngle) * 600) * ((self.player.stats.bullet_speed / 2) + 1)
    local vy = (math.sin(finalAngle) * 600) * ((self.player.stats.bullet_speed / 2) + 1)
    local b = nil

    if self.bulletType then
        if self.bulletType == "bullet" then
            b = self.res.Bullet:new(self.player, bx, by, vx, vy)
        elseif self.bulletType == "drone" then
            b = self.res.Drone:new(self.player, bx, by, vx, vy, self.player.tankData.droneType)
            b.speed = b.speed * (self.player.stats.bullet_speed + 1)
            table.insert(self.player.drones, b)
        elseif self.bulletType == "trap" then
            b = self.res.Trap:new(self.player, bx, by, vx, vy)
        elseif self.bulletType == "factoryDrone" then
            b = self.res.FactoryDrone:new(self.player, bx, by, vx, vy)
            b.speed = b.speed * (self.player.stats.bullet_speed + 1)
            table.insert(self.player.drones, b)
        else
            b = self.res.Bullet:new(self.player, bx, by, vx, vy)
        end
    else
        b = self.res.Bullet:new(self.player, bx, by, vx, vy)
    end

    -- APPLY STATS TO BULLET
    -- Base Damage (5) + 2 per level
    b.damage = b.damage + (self.player.stats.bullet_damage * 2)

    -- APPLY BULLET SIZE MULTIPLIER
    -- This scales the standard bullet radius by the barrel's config
    b.radius = b.radius * self.bulletSize
    
    -- Base Penetration (1) + 1 per level
    -- (In diep.io, penetration is like 'health' for bullets)
    b.penetration = b.penetration + self.player.stats.bullet_penetration

    return b
end

function Barrel:draw(alpha, dt, style)
    local a = alpha or 1
    if self.recoilOffset > 0 then
        self.recoilOffset = self.recoilOffset - (self.recoilOffset * 20 * dt)
    end

    -- Calculate dynamic dimensions for drawing
    local r = self.barrelBase.radius
    local w = r * self.widthMult
    local l = r * self.lengthMult
    local y = (r * self.yOffsetMult) - self.recoilOffset
    local x = -(self.xOffsetMult * r)
    local tw = w * self.tipWidthMult 

    love.graphics.push()
    love.graphics.rotate(self.angleOffset)
    love.graphics.rotate(-pi2)

    local vertices = {
        x - w/2,  y,      
        x + w/2,  y,      
        x + tw/2, y + l,  
        x - tw/2, y + l   
    }
    -- Draw Fill
    love.graphics.setLineJoin("bevel")
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], a)
    love.graphics.polygon("fill", vertices)

    -- Draw Outline
    love.graphics.setLineWidth(self.outline_thickness)
    if style == "New" then
        love.graphics.setColor(self.outline_color[1], self.outline_color[2], self.outline_color[3], a)
    elseif style == "Old" then
        love.graphics.setColor(0.3, 0.3, 0.3, a)
    else
        love.graphics.setColor(self.outline_color[1], self.outline_color[2], self.outline_color[3], a)
    end
    love.graphics.polygon("line", vertices)
    love.graphics.setLineJoin("miter")

    love.graphics.pop()
end

return Barrel