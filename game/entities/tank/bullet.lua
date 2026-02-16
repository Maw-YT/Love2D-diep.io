-- game/bullet.lua

local Bullet = {}
Bullet.__index = Bullet

local Physics = require "game.system.physics"

function Bullet:new(player, x, y, vx, vy)
    local self = setmetatable({}, Bullet)
    self.player = player
    self.x = x
    self.y = y
    self.radius = (player.radius * 0.7) / 2
    self.vx = vx
    self.vy = vy
    self.mainVx = vx
    self.mainVy = vy
    self.color = player.color
    self.outline_color = player.outline_color
    self.isdead = false
    self.damage = 5
    self.penetration = 1
    self.lifetime = 5.0  -- 5 seconds  
    self.age = 0  

    self.type = "bullet"

    return self
end

function Bullet:update(dt)
    -- Update position  
    self.x = self.x + self.vx * dt  
    self.y = self.y + self.vy * dt  

    self.vx = self.vx + (self.mainVx * (FRICTION / 3))
    self.vy = self.vy + (self.mainVy * (FRICTION / 3))

    Physics.applyPhysics(self, dt)
      
    -- Update age and check lifetime  
    self.age = self.age + dt  
    if self.age >= self.lifetime then  
        self.isdead = true  
    end 
end

function Bullet:draw(alpha, style)
    local a = alpha or 1
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], a)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    love.graphics.setLineWidth(2)
    if style == "New" then
        love.graphics.setColor(self.outline_color[1], self.outline_color[2], self.outline_color[3], a)
    elseif style == "Old" then
        love.graphics.setColor(0.3, 0.3, 0.3, a)
    else
        love.graphics.setColor(self.outline_color[1], self.outline_color[2], self.outline_color[3], a)
    end
    love.graphics.circle("line", self.x, self.y, self.radius)

    love.graphics.setLineWidth(1)
end

return Bullet