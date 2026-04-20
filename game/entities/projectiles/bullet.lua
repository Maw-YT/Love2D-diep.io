-- game/entities/projectiles/bullet.lua

local EntityBase = require "game.native.entityBase"
local Bullet = setmetatable({}, { __index = EntityBase })
Bullet.__index = Bullet

local Physics = require "game.system.physics"

function Bullet:new(player, x, y, vx, vy)
    local self = EntityBase:new({
        type = "bullet",
        team = (player and player.team) or player,
        owner = player,
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        radius = (player.radius * 0.7) / 2,
        angle = 0,
    })
    setmetatable(self, Bullet)
    self.player = player
    self.mainVx = vx
    self.mainVy = vy
    self.color = player.color
    self.outline_color = player.outline_color
    self.damage = 5
    self.penetration = 1
    self.lifetime = 5.0
    self.age = 0

    return self
end

function Bullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    self.vx = self.vx + (self.mainVx * (FRICTION / 3))
    self.vy = self.vy + (self.mainVy * (FRICTION / 3))

    Physics.applyPhysics(self, dt)

    self.age = self.age + dt
    if self.age >= self.lifetime then
        self:setDead(true)
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
