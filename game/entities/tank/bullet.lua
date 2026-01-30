-- game/bullet.lua

local Bullet = {}
Bullet.__index = Bullet

function Bullet:new(player, x, y, vx, vy)
    local self = setmetatable({}, Bullet)
    self.player = player
    self.x = x
    self.y = y
    self.radius = (player.radius * 0.7) / 2
    self.vx = vx
    self.vy = vy
    self.color = player.color
    self.outline_color = player.outline_color
    self.isdead = false
    self.damage = 5
    self.penetration = 1

    self.type = "bullet"

    return self
end

function Bullet:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    local speed = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    if speed > 10 then
        local drag_mag = 1 * speed * dt
        self.vx = self.vx - (self.vx / speed) * drag_mag
        self.vy = self.vy - (self.vy / speed) * drag_mag
    else
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