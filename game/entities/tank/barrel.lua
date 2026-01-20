-- game/barrel.lua
local Barrel = {}
Barrel.__index = Barrel
local loader = require "game.utils.loader"
local pi2 = (math.pi / 2)

function Barrel:new(player, xOffset, fire_delay, bulletType, config)
    local self = setmetatable({}, Barrel)
    self.player = player
    self.xOffset = -xOffset
    self.bulletType = bulletType or "bullet"
    self.fire_delay = fire_delay or 0
    self.has_fired_this_cycle = false
    self.recoilOffset = 0
    self.maxRecoil = 12
    self.res = loader.loadAll()

    -- New configuration options from classes.lua
    self.config = config or {}
    self.isTrapezoid = self.config.isTrapezoid or false
    -- tipWidth is a multiplier of the base width (e.g., 1.5 is 50% wider at the tip)
    self.tipWidthMult = config.tipWidth or 1.0
    -- Visual Scaling
    local widthMult = config.widthMult or 0.7
    local lengthMult = config.lengthMult or 1.3

    self.yOffset = player.radius * 0.4
    self.length = player.radius * lengthMult
    self.width = player.radius * widthMult

    self.spread = 0.05
    self.color = {0.6, 0.6, 0.6}
    self.outline_color = {0.5, 0.5, 0.5}
    self.outline_thickness = 3.0
    return self
end

function Barrel:fire()
    -- Only this specific barrel instance recoils
    self.recoilOffset = self.maxRecoil

    local baseAngle = self.player.angle
    local spawnDist = self.player.radius + self.length - self.yOffset
    
    -- THE FIX: Changed -sin to +sin for xOffset to align with visual rotation
    local bx = self.player.x + math.cos(baseAngle) * spawnDist + math.sin(baseAngle) * self.xOffset
    local by = self.player.y + math.sin(baseAngle) * spawnDist - math.cos(baseAngle) * self.xOffset
    
    local finalAngle = baseAngle + (love.math.random() - 0.5) * 2 * self.spread
    local vx = (math.cos(finalAngle) * 600) * (self.player.stats.bullet_speed + 1)
    local vy = (math.sin(finalAngle) * 600) * (self.player.stats.bullet_speed + 1)
    local b = nil

    if self.bulletType then
        if self.bulletType == "bullet" then
            b = self.res.Bullet:new(self.player, bx, by, vx, vy)
        elseif self.bulletType == "drone" then
            b = self.res.Drone:new(self.player, bx, by, vx, vy)
            b.speed = b.speed * ((self.player.stats.bullet_speed * 2) + 1)
        else
            b = self.res.Bullet:new(self.player, bx, by, vx, vy)
        end
    else
        b = self.res.Bullet:new(self.player, bx, by, vx, vy)
    end

    -- APPLY STATS TO BULLET
    -- Base Damage (5) + 2 per level
    b.damage = 5 + (self.player.stats.bullet_damage * 2)
    
    -- Base Penetration (1) + 1 per level
    -- (In diep.io, penetration is like 'health' for bullets)
    b.penetration = 1 + self.player.stats.bullet_penetration

    return b
end

function Barrel:draw(alpha, dt, style)
    local a = alpha or 1
    if self.recoilOffset > 0 then
        self.recoilOffset = self.recoilOffset - (self.recoilOffset * 20 * dt)
    end

    love.graphics.push()
    love.graphics.rotate(-pi2) 

    local x = self.xOffset
    local y = self.yOffset - self.recoilOffset
    local w = self.width
    local l = self.length
    local tw = w * self.tipWidthMult -- The calculated width of the tip

    -- Define the 4 points of the barrel (Rectangle or Trapezoid)
    -- Vertices are calculated relative to the rotation point
    local vertices = {
        x - w/2,  y,      -- Bottom Left (near player body)
        x + w/2,  y,      -- Bottom Right (near player body)
        x + tw/2, y + l,  -- Top Right (tip)
        x - tw/2, y + l   -- Top Left (tip)
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